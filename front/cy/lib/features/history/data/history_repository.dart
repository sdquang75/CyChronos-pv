import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

/// 走行履歴(トリップ)の取得を行うリポジトリ
class HistoryRepository {
  final Dio _dio;

  HistoryRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// ログ全件取得(GET /api/trips?user_id={user_id})。
  /// back/docs/API.md「2. ログ全件取得」の形式で、
  /// start_time の降順のトリップ一覧が返る(該当なしは空配列)。
  Future<List<Map<String, dynamic>>> fetchTrips({required int userId}) async {
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

  /// ログ単体取得(GET /api/trips/{trip_id})。
  /// back/docs/API.md「3. ログ単体取得」の形式で、トリップ詳細に
  /// そのトリップの座標ログ(locations、log_num昇順)が付いて返る。
  Future<Map<String, dynamic>> fetchTripDetail({
    required int userId,
    required int tripId,
  }) async {
    final response = await _dio.get(
      '/api/trips/$tripId',
      queryParameters: {'user_id': userId},
    );

    final data = response.data;
    if (data is! Map) {
      throw Exception('トリップ詳細の形式が不正です');
    }
    return Map<String, dynamic>.from(data);
  }
}
