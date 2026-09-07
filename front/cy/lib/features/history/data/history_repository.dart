import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

/// 走行履歴(トリップ)の取得を行うリポジトリ
class HistoryRepository {
  final Dio _dio;

  HistoryRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// ログ全件取得(GET /api/trips?user_id={user_id})。
  /// back/docs/API.md「2. ログ全件取得」の形式で、
  /// start_time の降順のトリップ一覧が返る(該当なしは空配列)。
  Future<List<Map<String, dynamic>>> fetchTrips({
    required int userId,
  }) async {
    final response = await _dio.get(
      '/api/trips',
      queryParameters: {'user_id': userId},
    );

    final data = response.data;
    if (data is! List) return [];

    // 想定外の要素(Map以外)は表示せず読み飛ばす
    return data
        .whereType<Map>()
        .map((trip) => Map<String, dynamic>.from(trip))
        .toList();
  }

  /// ログ単体取得(GET /api/trips/{trip_id}?user_id={user_id})。
  /// トリップ情報に加えて locations (走行座標ログの配列)を含むMapを返す。
  Future<Map<String, dynamic>?> fetchTripDetail({
    required int userId,
    required int tripId,
  }) async {
    final response = await _dio.get(
      '/api/trips/$tripId',
      queryParameters: {'user_id': userId},
    );

    final data = response.data;
    if (data is! Map) return null;
    return Map<String, dynamic>.from(data);
  }

  /// ログ削除(DELETE /api/trips/{trip_id}?user_id={user_id})。
  /// トリップを論理削除する(成功時は204 No Content)。
  Future<void> deleteTrip({
    required int userId,
    required int tripId,
  }) async {
    await _dio.delete(
      '/api/trips/$tripId',
      queryParameters: {'user_id': userId},
    );
  }
}
