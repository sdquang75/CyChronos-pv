import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/network/api_client.dart';

/// 走行中の現在地を受け取ってバッファし、まとめてバックエンドへ送る。
///
/// 1点ずつPOSTすると1時間の走行で数百リクエストになるため、ある程度たまってから
/// まとめて送る(/api/locations は points[] を受け付ける)。
/// 送信に失敗した点はバッファに残して次回再送するので、トンネルや山間部で
/// 一時的に圏外になっても軌跡が欠けにくい。
class TripLogger {
  TripLogger({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  /// 何メートル動いたら1点記録するか。信号待ちで同じ点が並ぶのを防ぐ
  static const int _distanceFilterMeters = 10;

  /// この件数たまったら送る
  static const int _flushThreshold = 20;

  /// たまっていなくてもこの間隔で送る(短い走行でも記録が残るように)
  static const Duration _flushInterval = Duration(seconds: 30);

  /// 1リクエストの上限(バックエンドの MAX_POINTS_PER_REQUEST と揃える)
  static const int _maxPointsPerRequest = 500;

  /// 圏外が続いたときにメモリを食いつぶさないための上限
  static const int _maxBufferedPoints = 2000;

  int? _tripId;
  StreamSubscription<Position>? _subscription;
  Timer? _timer;
  bool _flushing = false;
  final List<Map<String, dynamic>> _buffer = [];

  bool get isRunning => _tripId != null;

  /// 記録開始。位置情報が使えない場合でも例外は投げず、記録なしで続行する
  /// (記録はおまけで、案内そのものを止めたくないため)
  void start(int tripId) {
    if (_tripId != null) return; // 二重開始を防ぐ
    _tripId = tripId;

    try {
      _subscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: _distanceFilterMeters,
        ),
      ).listen(
        _add,
        onError: (Object error) {
          debugPrint('TripLogger: 位置情報の取得に失敗しました: $error');
        },
        cancelOnError: false,
      );
    } catch (error) {
      debugPrint('TripLogger: 位置情報の購読を開始できませんでした: $error');
    }

    _timer = Timer.periodic(_flushInterval, (_) => flush());
  }

  /// 記録終了。残っている点を送りきってから戻る。
  /// 走行実績(距離・平均速度)はサーバーがトリップ終了時に集計するため、
  /// この flush は終了APIを呼ぶ前に完了している必要がある
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;

    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) {
      // 購読解除は端末側の都合で返ってこないことがある。
      // ここで待つと「案内を終了」がそのまま固まってしまうので、完了は待たない
      unawaited(subscription.cancel().catchError((Object _) {}));
    }

    await flush();
    _tripId = null;
  }

  void _add(Position position) {
    final speed = position.speed;
    final accuracy = position.accuracy;

    _buffer.add({
      'lat': position.latitude,
      'lng': position.longitude,
      'recorded_at': position.timestamp.toUtc().toIso8601String(),
      // geolocator の speed は m/s。DBは km/h で持つので変換する
      'speed_kmh': speed.isFinite && speed >= 0 ? speed * 3.6 : null,
      'accuracy_m': accuracy.isFinite && accuracy >= 0 ? accuracy : null,
    });

    // 圏外が長引いた場合は古い点から捨てる(直近の軌跡を優先する)
    if (_buffer.length > _maxBufferedPoints) {
      _buffer.removeRange(0, _buffer.length - _maxBufferedPoints);
    }

    if (_buffer.length >= _flushThreshold) flush();
  }

  /// バッファの点をサーバーへ送る。失敗した点は残して次回再送する
  Future<void> flush() async {
    final tripId = _tripId;
    if (tripId == null || _flushing || _buffer.isEmpty) return;

    _flushing = true;
    try {
      while (_buffer.isNotEmpty) {
        final chunk = _buffer.take(_maxPointsPerRequest).toList();
        await _dio.post(
          '/api/locations',
          data: {'trip_id': tripId, 'points': chunk},
        );
        _buffer.removeRange(0, chunk.length);
      }
    } catch (error) {
      // 送れなかった点はバッファに残し、次のタイミングでまとめて再送する
      debugPrint('TripLogger: 座標の送信に失敗しました(次回再送します): $error');
    } finally {
      _flushing = false;
    }
  }

  /// 画面破棄時の後始末。送信の完了は待たない
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _timer?.cancel();
    _timer = null;
    _tripId = null;
    _buffer.clear();
  }
}
