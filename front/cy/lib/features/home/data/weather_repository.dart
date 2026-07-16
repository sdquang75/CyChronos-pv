import 'package:dio/dio.dart';
import '../domain/weather_data.dart';

// Fetches current weather from Open-Meteo (free, no API key required).
// https://open-meteo.com/en/docs
class WeatherRepository {
  final Dio _dio;

  WeatherRepository({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: 'https://api.open-meteo.com/v1'));

  Future<WeatherData> fetchCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get(
      '/forecast',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'current':
            'temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code',
      },
    );
    return WeatherData.fromOpenMeteoJson(response.data as Map<String, dynamic>);
  }
}
