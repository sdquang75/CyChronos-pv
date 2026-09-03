class CalorieCalculator {
  // 体重入力を不要にするため、60kgを基準に計算する
  static const double baseWeightKg = 60.0;

  static int? calculate({
    required double distanceM,
    required double durationSec,
  }) {
    if (distanceM <= 0 || durationSec <= 0) {
      return null;
    }

    final double distanceKm = distanceM / 1000;
    final double durationHours = durationSec / 3600;
    final double durationMinutes = durationSec / 60;

    // 平均速度を計算
    final double averageSpeedKmh = distanceKm / durationHours;

    // 平均速度からMETsを決定
    final double mets = _metsForSpeed(averageSpeedKmh);

    // 推定消費カロリー
    final double calories =
        mets * 3.5 * baseWeightKg / 200 * durationMinutes;

    return calories.round();
  }

  static double _metsForSpeed(double speedKmh) {
    if (speedKmh < 16.0) {
      return 4.0;
    }

    if (speedKmh < 19.0) {
      return 5.8;
    }

    if (speedKmh < 22.0) {
      return 6.8;
    }

    return 8.0;
  }
}