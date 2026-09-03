import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class RecommendationRepository {
  final Dio _dio;

  RecommendationRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  // TODO: confirm final endpoint path & payload/response shape with backend.
  Future<dynamic> fetchRecommendations({
    required double latitude,
    required double longitude,
    required String type,
    required int minutes,
    required String mode,
    required int stayMinutes,
  }) async {
    final response = await _dio.get(
      '/api/suggest',
      queryParameters: {
        'lat': latitude,
        'lng': longitude,
        'type': type,
        'minutes': minutes,
        'mode': mode,
        'stayMinutes': stayMinutes,
      },
    );
    return response.data;
  }
}
