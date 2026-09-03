import 'dart:math' as math;

import '../data/route_repository.dart';

class NavigationSnapshot {
  final int nearestSegmentIndex;
  final double offRouteDistanceM;
  final double remainingDistanceM;
  final double remainingDurationSec;
  final int? upcomingStepIndex;
  final double? distanceToManeuverM;

  const NavigationSnapshot({
    required this.nearestSegmentIndex,
    required this.offRouteDistanceM,
    required this.remainingDistanceM,
    required this.remainingDurationSec,
    required this.upcomingStepIndex,
    required this.distanceToManeuverM,
  });
}

/// GPS座標をルート線へ投影し、残距離・次の案内・ルート逸脱距離を計算する。
class NavigationEngine {
  final CyclingRoute route;
  late final List<double> _cumulativeDistanceM;
  late final List<double> _stepOffsetsM;
  late final double _geometryDistanceM;

  NavigationEngine(this.route) {
    if (route.points.length < 2) {
      throw ArgumentError('案内には2点以上のルート形状が必要です');
    }

    _cumulativeDistanceM = List<double>.filled(route.points.length, 0);
    for (var index = 1; index < route.points.length; index++) {
      _cumulativeDistanceM[index] =
          _cumulativeDistanceM[index - 1] +
          _distanceBetween(route.points[index - 1], route.points[index]);
    }
    _geometryDistanceM = _cumulativeDistanceM.last;
    _stepOffsetsM = route.steps
        .map(
          (step) =>
              _project(step.maneuverPoint[1], step.maneuverPoint[0]).alongM,
        )
        .toList(growable: false);
  }

  NavigationSnapshot update({
    required double latitude,
    required double longitude,
  }) {
    final projection = _project(latitude, longitude);
    final scale =
        _geometryDistanceM > 0 && route.distanceM > 0
            ? route.distanceM / _geometryDistanceM
            : 1.0;
    final routeDistance =
        route.distanceM > 0 ? route.distanceM : _geometryDistanceM;
    final travelledM = (projection.alongM * scale).clamp(0.0, routeDistance);
    final remainingM = math.max(0.0, routeDistance - travelledM);
    final duration = route.durationSec > 0 ? route.durationSec : 0.0;
    final remainingDuration =
        routeDistance > 0 ? duration * (remainingM / routeDistance) : 0.0;

    int? upcomingStepIndex;
    double? distanceToManeuverM;
    if (_stepOffsetsM.isNotEmpty) {
      // 出発案内は現在位置と重なるため、10m以上先にある最初の手順を案内する。
      upcomingStepIndex = _stepOffsetsM.indexWhere(
        (offset) => offset > projection.alongM + 10,
      );
      if (upcomingStepIndex < 0) upcomingStepIndex = _stepOffsetsM.length - 1;
      distanceToManeuverM = math.max(
        0,
        (_stepOffsetsM[upcomingStepIndex] - projection.alongM) * scale,
      );
    }

    return NavigationSnapshot(
      nearestSegmentIndex: projection.segmentIndex,
      offRouteDistanceM: projection.distanceM,
      remainingDistanceM: remainingM,
      remainingDurationSec: remainingDuration,
      upcomingStepIndex: upcomingStepIndex,
      distanceToManeuverM: distanceToManeuverM,
    );
  }

  _RouteProjection _project(double latitude, double longitude) {
    var bestDistance = double.infinity;
    var bestAlong = 0.0;
    var bestSegment = 0;
    final latitudeRadians = latitude * math.pi / 180;
    final longitudeScale = 111320 * math.cos(latitudeRadians);

    for (var index = 0; index < route.points.length - 1; index++) {
      final start = route.points[index];
      final end = route.points[index + 1];
      final startX = (start[0] - longitude) * longitudeScale;
      final startY = (start[1] - latitude) * 110540;
      final endX = (end[0] - longitude) * longitudeScale;
      final endY = (end[1] - latitude) * 110540;
      final dx = endX - startX;
      final dy = endY - startY;
      final lengthSquared = dx * dx + dy * dy;
      final rawT =
          lengthSquared == 0
              ? 0.0
              : -(startX * dx + startY * dy) / lengthSquared;
      final t = rawT.clamp(0.0, 1.0);
      final projectedX = startX + dx * t;
      final projectedY = startY + dy * t;
      final distance = math.sqrt(
        projectedX * projectedX + projectedY * projectedY,
      );

      if (distance < bestDistance) {
        bestDistance = distance;
        bestSegment = index;
        final segmentLength =
            _cumulativeDistanceM[index + 1] - _cumulativeDistanceM[index];
        bestAlong = _cumulativeDistanceM[index] + segmentLength * t;
      }
    }

    return _RouteProjection(
      segmentIndex: bestSegment,
      distanceM: bestDistance,
      alongM: bestAlong,
    );
  }
}

class _RouteProjection {
  final int segmentIndex;
  final double distanceM;
  final double alongM;

  const _RouteProjection({
    required this.segmentIndex,
    required this.distanceM,
    required this.alongM,
  });
}

double _distanceBetween(List<double> first, List<double> second) {
  const earthRadiusM = 6371000.0;
  final lat1 = first[1] * math.pi / 180;
  final lat2 = second[1] * math.pi / 180;
  final deltaLat = (second[1] - first[1]) * math.pi / 180;
  final deltaLng = (second[0] - first[0]) * math.pi / 180;
  final a =
      math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
      math.cos(lat1) *
          math.cos(lat2) *
          math.sin(deltaLng / 2) *
          math.sin(deltaLng / 2);
  return earthRadiusM * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}
