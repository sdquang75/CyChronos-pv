import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

/// バックの /api/maps/route から取り出した、フロントで使う分だけのルート情報
class CyclingRoute {
  final double distanceM; // ルートの総距離(m)
  final double durationSec; // ルートの所要時間(秒)
  final List<List<double>> points; // ルートの形。[経度, 緯度] の点の並び(プレビュー描画に使う)
  final List<NavigationStep> steps; // 曲がり角・到着などの案内手順

  const CyclingRoute({
    required this.distanceM,
    required this.durationSec,
    required this.points,
    this.steps = const [],
  });

  factory CyclingRoute.fromMap(Map<String, dynamic> route) {
    final geometry = route['geometry'] as Map?;
    final points = _parseCoordinates(geometry?['coordinates']);
    final legs = (route['legs'] as List?) ?? const [];
    final steps = <NavigationStep>[];

    for (final rawLeg in legs.whereType<Map>()) {
      final rawSteps = (rawLeg['steps'] as List?) ?? const [];
      for (final rawStep in rawSteps.whereType<Map>()) {
        final maneuver = rawStep['maneuver'] as Map?;
        final location = _parsePoint(maneuver?['location']);
        if (location == null) continue;
        steps.add(
          NavigationStep(
            instruction:
                maneuver?['instruction']?.toString().trim().isNotEmpty == true
                    ? maneuver!['instruction'].toString().trim()
                    : '道なりに進みます',
            roadName: rawStep['name']?.toString() ?? '',
            maneuverType: maneuver?['type']?.toString() ?? 'continue',
            modifier: maneuver?['modifier']?.toString(),
            distanceM: (rawStep['distance'] as num?)?.toDouble() ?? 0,
            durationSec: (rawStep['duration'] as num?)?.toDouble() ?? 0,
            maneuverPoint: location,
          ),
        );
      }
    }

    return CyclingRoute(
      distanceM: (route['distance'] as num?)?.toDouble() ?? 0,
      durationSec: (route['duration'] as num?)?.toDouble() ?? 0,
      points: points,
      steps: steps,
    );
  }
}

class NavigationStep {
  final String instruction;
  final String roadName;
  final String maneuverType;
  final String? modifier;
  final double distanceM;
  final double durationSec;
  final List<double> maneuverPoint; // [経度, 緯度]

  const NavigationStep({
    required this.instruction,
    required this.roadName,
    required this.maneuverType,
    required this.modifier,
    required this.distanceM,
    required this.durationSec,
    required this.maneuverPoint,
  });
}

List<List<double>> _parseCoordinates(dynamic value) {
  final coordinates = value is List ? value : const [];
  return coordinates
      .whereType<List>()
      .map(_parsePoint)
      .whereType<List<double>>()
      .toList(growable: false);
}

List<double>? _parsePoint(dynamic value) {
  if (value is! List || value.length < 2) return null;
  final lng = value[0];
  final lat = value[1];
  if (lng is! num || lat is! num) return null;
  return [lng.toDouble(), lat.toDouble()];
}

class RouteRepository {
  final Dio _dio;

  RouteRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// 現在地→目的地の自転車ルートをバック経由(Mapbox Directions)で取得する
  Future<CyclingRoute> fetchCyclingRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final response = await _dio.get(
      '/api/maps/route',
      queryParameters: {
        'fromLat': fromLat,
        'fromLng': fromLng,
        'toLat': toLat,
        'toLng': toLng,
      },
    );

    // Mapboxのレスポンスは { routes: [ルート候補たち] }。先頭が推奨ルート
    final routes = (response.data?['routes'] as List?) ?? const [];
    if (routes.isEmpty) {
      throw Exception('ルートが見つかりませんでした');
    }
    final route = Map<String, dynamic>.from(routes.first as Map);

    final cyclingRoute = CyclingRoute.fromMap(route);
    if (cyclingRoute.points.length < 2) {
      throw const FormatException('ルート形状を取得できませんでした');
    }
    return cyclingRoute;
  }

  /// トリップ開始をバックに記録する。place_id を送ると「訪問済み」として次回の提案から除外される
  Future<int> startTrip({
    required int userId,
    String? placeId,
    String? destinationName,
  }) async {
    final response = await _dio.post(
      '/api/trips/start',
      data: {
        'user_id': userId,
        if (placeId != null && placeId.isNotEmpty)
          'destination_place_id': placeId,
        if (destinationName != null) 'destination_name': destinationName,
      },
    );
    return (response.data['trip_id'] as num).toInt();
  }

  /// トリップ終了をバックに記録する(statusがcompletedになり走行履歴として残る)
  Future<void> endTrip({required int userId, required int tripId}) async {
    await _dio.post('/api/trips/$tripId/end', data: {'user_id': userId});
  }
}
