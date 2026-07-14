import 'package:flutter/material.dart';

// Maps Open-Meteo's WMO weather codes to a short label and icon.
// https://open-meteo.com/en/docs (see "WMO Weather interpretation codes")
class WeatherCondition {
  final String label;
  final IconData icon;

  const WeatherCondition(this.label, this.icon);

  factory WeatherCondition.fromCode(int code) {
    if (code == 0) {
      return const WeatherCondition('快晴', Icons.wb_sunny_rounded);
    }
    if (code <= 2) {
      return const WeatherCondition('晴れ', Icons.wb_sunny_rounded);
    }
    if (code == 3) return const WeatherCondition('曇り', Icons.cloud_rounded);
    if (code <= 48) return const WeatherCondition('霧', Icons.foggy);
    if (code <= 57) {
      return const WeatherCondition('霧雨', Icons.grain_rounded);
    }
    if (code <= 67) {
      return const WeatherCondition('雨', Icons.water_drop_rounded);
    }
    if (code <= 77) {
      return const WeatherCondition('雪', Icons.ac_unit_rounded);
    }
    if (code <= 82) {
      return const WeatherCondition('にわか雨', Icons.water_drop_rounded);
    }
    if (code <= 86) {
      return const WeatherCondition('雪', Icons.ac_unit_rounded);
    }
    if (code <= 99) {
      return const WeatherCondition('雷雨', Icons.thunderstorm_rounded);
    }
    return const WeatherCondition('晴れ', Icons.wb_sunny_rounded);
  }
}
