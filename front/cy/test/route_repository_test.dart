import 'package:flutter_test/flutter_test.dart';

import 'package:cy/features/route_confirm/data/route_repository.dart';

void main() {
  test('Mapboxレスポンスからルート形状と日本語の案内手順を読み取る', () {
    final route = CyclingRoute.fromMap({
      'distance': 2596.4,
      'duration': 617.2,
      'geometry': {
        'coordinates': [
          [139.7673, 35.6812],
          [139.7528, 35.6852],
        ],
      },
      'legs': [
        {
          'steps': [
            {
              'distance': 120.5,
              'duration': 30.0,
              'name': '八重洲中央口前',
              'maneuver': {
                'instruction': '八重洲中央口前を左方向です。',
                'type': 'turn',
                'modifier': 'left',
                'location': [139.7600, 35.6830],
              },
            },
          ],
        },
      ],
    });

    expect(route.distanceM, 2596.4);
    expect(route.durationSec, 617.2);
    expect(route.points, hasLength(2));
    expect(route.steps, hasLength(1));
    expect(route.steps.single.instruction, '八重洲中央口前を左方向です。');
    expect(route.steps.single.modifier, 'left');
    expect(route.steps.single.maneuverPoint, [139.7600, 35.6830]);
  });

  test('座標が壊れた案内手順は無視して画面クラッシュを防ぐ', () {
    final route = CyclingRoute.fromMap({
      'geometry': {
        'coordinates': [
          [139.0, 35.0],
          ['invalid', 35.1],
          [139.2, 35.2],
        ],
      },
      'legs': [
        {
          'steps': [
            {
              'maneuver': {'instruction': '右折', 'location': []},
            },
          ],
        },
      ],
    });

    expect(route.points, [
      [139.0, 35.0],
      [139.2, 35.2],
    ]);
    expect(route.steps, isEmpty);
  });
}
