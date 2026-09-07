import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cy/features/history/data/history_repository.dart';

class _MockAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;

  _MockAdapter(this.handler);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }
}

void main() {
  test('fetchTrips: user_idをクエリに付与してGETリクエストを送り、一覧を返す', () async {
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.httpClientAdapter = _MockAdapter((options) {
      captured = options;
      return ResponseBody.fromString(
        '[{"trip_id": 1, "destination_name": "大阪城公園", "total_distance_m": 12500}]',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    final repo = HistoryRepository(dio: dio);
    final trips = await repo.fetchTrips(userId: 42);

    expect(captured?.path, '/api/trips');
    expect(captured?.queryParameters['user_id'], 42);
    expect(trips, hasLength(1));
    expect(trips.first['trip_id'], 1);
    expect(trips.first['destination_name'], '大阪城公園');
  });

  test('fetchTripDetail: 指定tripIdの詳細とlocationsを取得する', () async {
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.httpClientAdapter = _MockAdapter((options) {
      captured = options;
      return ResponseBody.fromString(
        '{"trip_id": 1, "destination_name": "大阪城公園", "locations": [{"log_num": 1, "lat": 34.69, "lng": 135.50}]}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    final repo = HistoryRepository(dio: dio);
    final detail = await repo.fetchTripDetail(userId: 42, tripId: 1);

    expect(captured?.path, '/api/trips/1');
    expect(captured?.queryParameters['user_id'], 42);
    expect(detail?['trip_id'], 1);
    expect(detail?['locations'], hasLength(1));
  });

  test('deleteTrip: 指定tripIdをDELETEリクエストで削除する', () async {
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.httpClientAdapter = _MockAdapter((options) {
      captured = options;
      return ResponseBody.fromString('', 204);
    });

    final repo = HistoryRepository(dio: dio);
    await repo.deleteTrip(userId: 42, tripId: 99);

    expect(captured?.method, 'DELETE');
    expect(captured?.path, '/api/trips/99');
    expect(captured?.queryParameters['user_id'], 42);
  });
}
