import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:cy/features/home/data/location_service.dart';
import 'package:cy/features/home/data/recommendation_repository.dart';
import 'package:cy/features/home/domain/recommendation_state.dart';
import 'package:cy/features/home/presentation/providers/recommendation_provider.dart';

class _FakeLocationService extends LocationService {
  Position _pos() => Position(
        longitude: 139.7673,
        latitude: 35.6812,
        timestamp: DateTime(2026, 9, 4),
        accuracy: 1,
        altitude: 0,
        altitudeAccuracy: 1,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

  @override
  Future<Position> getFastPosition({
    Duration maxAge = const Duration(minutes: 5),
  }) async => _pos();

  @override
  Future<Position> getCurrentPosition() async => _pos();
}

// 指定した DioException を投げるリポジトリ
class _FailingRecommendationRepository extends RecommendationRepository {
  _FailingRecommendationRepository(this.error) : super(dio: Dio());

  final DioException error;

  @override
  Future<dynamic> fetchRecommendations({
    required double latitude,
    required double longitude,
    required String type,
    required int minutes,
    required String mode,
    required int stayMinutes,
    bool? includeVisited,
  }) {
    throw error;
  }
}

Future<String> _messageFor(DioException error) async {
  final notifier = RecommendationNotifier(
    _FakeLocationService(),
    _FailingRecommendationRepository(error),
  );

  await notifier.fetchForCurrentLocation(
    minutes: 45,
    type: 'cafe',
    mode: 'one_way',
    stayMinutes: 0,
  );

  final state = notifier.state;
  expect(state, isA<RecommendationError>());
  final message = (state as RecommendationError).message;

  // 例外の内部情報はユーザーに見せない
  expect(message, isNot(contains('DioException')));
  expect(message, isNot(contains('Exception')));

  notifier.dispose();
  return message;
}

void main() {
  test('サーバーへ届かないときは「接続できない」と伝える(電波のせいにしない)', () async {
    final message = await _messageFor(
      DioException(
        requestOptions: RequestOptions(path: '/api/suggest'),
        type: DioExceptionType.connectionError,
        message: 'Connection refused',
      ),
    );

    // バックエンド未起動や接続先の設定ミスが原因なので、そこへ誘導する
    expect(message, contains('サーバーに接続できませんでした'));
    expect(message, contains('バックエンド'));
    expect(message, isNot(contains('Connection refused')));
  });

  test('応答が返らないときはタイムアウトとして伝える', () async {
    final message = await _messageFor(
      DioException(
        requestOptions: RequestOptions(path: '/api/suggest'),
        type: DioExceptionType.receiveTimeout,
      ),
    );

    expect(message, contains('応答がありませんでした'));
  });

  test('サーバーがエラー文言を返したときはそれをそのまま見せる', () async {
    final message = await _messageFor(
      DioException(
        requestOptions: RequestOptions(path: '/api/suggest'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/suggest'),
          statusCode: 502,
          data: {'error': 'Mapbox APIの呼び出しに失敗しました'},
        ),
      ),
    );

    // 外部API障害と通信不良は原因が違うので、区別できる文言にする
    expect(message, 'Mapbox APIの呼び出しに失敗しました');
  });

  test('認証切れは再ログインへ誘導する', () async {
    final message = await _messageFor(
      DioException(
        requestOptions: RequestOptions(path: '/api/suggest'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/suggest'),
          statusCode: 401,
          data: 'Unauthorized',
        ),
      ),
    );

    expect(message, contains('ログイン'));
  });
}
