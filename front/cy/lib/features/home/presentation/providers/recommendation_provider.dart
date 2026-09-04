import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error_message.dart';
import '../../data/location_service.dart';
import '../../data/recommendation_repository.dart';
import '../../domain/recommendation_state.dart';

final locationServiceProvider = Provider<LocationService>(
  (_) => LocationService(),
);

final recommendationRepositoryProvider = Provider<RecommendationRepository>(
  (_) => RecommendationRepository(),
);

final recommendationProvider =
    StateNotifierProvider<RecommendationNotifier, RecommendationState>(
      (ref) => RecommendationNotifier(
        ref.watch(locationServiceProvider),
        ref.watch(recommendationRepositoryProvider),
      ),
    );

class RecommendationNotifier extends StateNotifier<RecommendationState> {
  final LocationService _locationService;
  final RecommendationRepository _repo;

  RecommendationNotifier(this._locationService, this._repo)
    : super(const RecommendationInitial());

  Future<void> fetchForCurrentLocation({
    required int minutes,
    required String type,
    required String mode,
    required int stayMinutes,
  }) async {
    state = const RecommendationLocating();
    try {
      final position = await _locationService.getCurrentPosition();
      debugPrint(
        '[recommendation] got position: ${position.latitude}, ${position.longitude}',
      );

      state = const RecommendationLoading();
      final data = await _repo.fetchRecommendations(
        latitude: position.latitude,
        longitude: position.longitude,
        type: type,
        minutes: minutes,
        mode: mode,
        stayMinutes: stayMinutes,
      );
      state = RecommendationLoaded(data);
    } on LocationServiceDisabledException {
      state = const RecommendationLocationServiceDisabled();
    } on LocationPermissionDeniedForeverException {
      state = const RecommendationPermissionDeniedForever();
    } on LocationPermissionDeniedException {
      state = const RecommendationPermissionDenied();
    } catch (error) {
      debugPrint('[recommendation] fetch failed: $error');
      // 失敗理由(サーバー未起動・接続先設定ミス・外部APIの障害など)を切り分けて表示する
      state = RecommendationError(
        describeApiError(
          error,
          fallback: 'おすすめスポットを取得できませんでした。時間をおいてもう一度お試しください。',
        ),
      );
    }
  }
}
