import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:cy/features/home/data/location_service.dart';
import 'package:cy/features/home/data/recommendation_repository.dart';
import 'package:cy/features/home/domain/recommendation_state.dart';
import 'package:cy/features/home/presentation/providers/recommendation_provider.dart';

class _FakeLocationService extends LocationService {
  @override
  Future<Position> getCurrentPosition() async {
    return Position(
      longitude: 139.7673,
      latitude: 35.6812,
      timestamp: DateTime(2026, 9, 4),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 1,
      speed: 0,
      speedAccuracy: 1,
    );
  }
}

class _FailingRecommendationRepository extends RecommendationRepository {
  _FailingRecommendationRepository() : super(dio: Dio());

  @override
  Future<dynamic> fetchRecommendations({
    required double latitude,
    required double longitude,
    required String type,
    required int minutes,
    required String mode,
    required int stayMinutes,
  }) {
    throw DioException(
      requestOptions: RequestOptions(path: '/api/suggest'),
      type: DioExceptionType.connectionError,
      message: 'Connection refused',
    );
  }
}

void main() {
  test('通信失敗時はDioExceptionを画面向け状態に露出しない', () async {
    final notifier = RecommendationNotifier(
      _FakeLocationService(),
      _FailingRecommendationRepository(),
    );

    await notifier.fetchForCurrentLocation(
      minutes: 45,
      type: 'cafe',
      mode: 'one_way',
      stayMinutes: 0,
    );

    final state = notifier.state;
    expect(state, isA<RecommendationError>());
    final message = (state as RecommendationError).message;
    expect(message, contains('通信環境を確認'));
    expect(message, isNot(contains('DioException')));
    expect(message, isNot(contains('Connection refused')));

    notifier.dispose();
  });
}
