import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

/// バックの /api/maps/route から取り出した、フロントで使う分だけのルート情報
class CyclingRoute {
  final double distanceM; // ルートの総距離(m)
  final double durationSec; // ルートの所要時間(秒)
  final List<List<double>> points; // ルートの形。[経度, 緯度] の点の並び(プレビュー描画に使う)

  const CyclingRoute({
    required this.distanceM,
    required this.durationSec,
    required this.points,
  });
}

class RouteRepository {
  final Dio _dio;

  RouteRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// 現在地→目的地の自転車ルートをバック経由(Mapbox Directions)で取得する
  Future<CyclingRoute> fetchCyclingRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final response = await _dio.get(
      '/api/maps/route',
      queryParameters: {
        'fromLat': fromLat,
        'fromLng': fromLng,
        'toLat': toLat,
        'toLng': toLng,
      },
    );

    // Mapboxのレスポンスは { routes: [ルート候補たち] }。先頭が推奨ルート
    final routes = (response.data?['routes'] as List?) ?? const [];
    if (routes.isEmpty) {
      throw Exception('ルートが見つかりませんでした');
    }
    final route = Map<String, dynamic>.from(routes.first as Map);

    // 経路の形は geometry.coordinates に [経度, 緯度] の配列で入っている
    final geometry = route['geometry'] as Map?;
    final coordinates = (geometry?['coordinates'] as List?) ?? const [];
    final points = coordinates
        .whereType<List>()
        .where((point) => point.length >= 2)
        .map((point) => [
              (point[0] as num).toDouble(),
              (point[1] as num).toDouble(),
            ])
        .toList();

    return CyclingRoute(
      distanceM: (route['distance'] as num?)?.toDouble() ?? 0,
      durationSec: (route['duration'] as num?)?.toDouble() ?? 0,
      points: points,
    );
  }

  /// トリップ開始をバックに記録する。place_id を送ると「訪問済み」として次回の提案から除外される
  Future<int> startTrip({
    required int userId,
    String? placeId,
    String? destinationName,
  }) async {
    final response = await _dio.post(
      '/api/trips/start',
      data: {
        'user_id': userId,
        if (placeId != null && placeId.isNotEmpty) 'destination_place_id': placeId,
        if (destinationName != null) 'destination_name': destinationName,
      },
    );
    return (response.data['trip_id'] as num).toInt();
  }

  /// トリップ終了をバックに記録する(statusがcompletedになり走行履歴として残る)
  Future<void> endTrip({
    required int userId,
    required int tripId,
  }) async {
    await _dio.post(
      '/api/trips/$tripId/end',
      data: {'user_id': userId},
    );
  }
}
