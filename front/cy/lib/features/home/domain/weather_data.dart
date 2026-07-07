class WeatherData {
  final double temperatureC;
  final double windSpeedKmh;
  final int humidityPercent;
  final int weatherCode; // WMO weather interpretation code (Open-Meteo)

  const WeatherData({
    required this.temperatureC,
    required this.windSpeedKmh,
    required this.humidityPercent,
    required this.weatherCode,
  });

  factory WeatherData.fromOpenMeteoJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    return WeatherData(
      temperatureC: (current['temperature_2m'] as num).toDouble(),
      windSpeedKmh: (current['wind_speed_10m'] as num).toDouble(),
      humidityPercent: (current['relative_humidity_2m'] as num).round(),
      weatherCode: (current['weather_code'] as num).toInt(),
    );
  }
}
