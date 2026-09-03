import 'package:flutter_test/flutter_test.dart';

import 'package:cy/features/route_confirm/data/route_repository.dart';
import 'package:cy/features/route_confirm/domain/navigation_engine.dart';

const _route = CyclingRoute(
  distanceM: 200,
  durationSec: 100,
  points: [
    [139.0000, 35.0000],
    [139.0010, 35.0000],
    [139.0020, 35.0000],
  ],
  steps: [
    NavigationStep(
      instruction: '東へ進みます',
      roadName: '',
      maneuverType: 'depart',
      modifier: 'straight',
      distanceM: 100,
      durationSec: 50,
      maneuverPoint: [139.0000, 35.0000],
    ),
    NavigationStep(
      instruction: '右折します',
      roadName: 'テスト通り',
      maneuverType: 'turn',
      modifier: 'right',
      distanceM: 100,
      durationSec: 50,
      maneuverPoint: [139.0010, 35.0000],
    ),
    NavigationStep(
      instruction: '目的地に到着します',
      roadName: '',
      maneuverType: 'arrive',
      modifier: null,
      distanceM: 0,
      durationSec: 0,
      maneuverPoint: [139.0020, 35.0000],
    ),
  ],
);

void main() {
  test('ルート始点では次の右折と全体の残距離を返す', () {
    final snapshot = NavigationEngine(
      _route,
    ).update(latitude: 35.0000, longitude: 139.0000);

    expect(snapshot.upcomingStepIndex, 1);
    expect(snapshot.remainingDistanceM, closeTo(200, 2));
    expect(snapshot.distanceToManeuverM, closeTo(100, 2));
    expect(snapshot.offRouteDistanceM, closeTo(0, 0.5));
  });

  test('右折地点を通過すると到着案内へ進み、残距離が減る', () {
    final snapshot = NavigationEngine(
      _route,
    ).update(latitude: 35.0000, longitude: 139.0012);

    expect(snapshot.upcomingStepIndex, 2);
    expect(snapshot.remainingDistanceM, lessThan(100));
    expect(snapshot.remainingDurationSec, lessThan(50));
  });

  test('ルートから約110m離れた位置では逸脱距離を返す', () {
    final snapshot = NavigationEngine(
      _route,
    ).update(latitude: 35.0010, longitude: 139.0010);

    expect(snapshot.offRouteDistanceM, greaterThan(100));
    expect(snapshot.offRouteDistanceM, lessThan(120));
  });

  test('不正なルート形状は案内エンジンを作成できない', () {
    const invalidRoute = CyclingRoute(distanceM: 0, durationSec: 0, points: []);

    expect(() => NavigationEngine(invalidRoute), throwsArgumentError);
  });
}
