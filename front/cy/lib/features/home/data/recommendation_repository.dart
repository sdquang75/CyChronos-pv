import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class RecommendationRepository {
  final Dio _dio;

  RecommendationRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  // TODO: confirm final endpoint path & payload/response shape with backend.
  Future<dynamic> fetchRecommendations({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.post(
      '/api/recommendations',
      data: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return response.data;
  }
}
