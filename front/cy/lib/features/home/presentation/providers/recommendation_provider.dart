import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/location_service.dart';
import '../../data/recommendation_repository.dart';
import '../../domain/recommendation_state.dart';
import '../../../settings/data/settings_service.dart';

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
        ref,
      ),
    );

class RecommendationNotifier extends StateNotifier<RecommendationState> {
  final LocationService _locationService;
  final RecommendationRepository _repo;
  final Ref? _ref;

  RecommendationNotifier(this._locationService, this._repo, [this._ref])
    : super(const RecommendationInitial());

  Future<void> fetchForCurrentLocation({
    required int minutes,
    required String type,
    required String mode,
    required int stayMinutes,
    bool? includeVisited,
  }) async {
    state = const RecommendationLocating();
    try {
      final position = await _locationService.getFastPosition();
      debugPrint(
        '[recommendation] got position: ${position.latitude}, ${position.longitude}',
      );

      final shouldIncludeVisited = includeVisited ??
          (_ref?.read(settingsProvider).includeVisitedPlaces ?? false);

      state = const RecommendationLoading();
      final data = await _repo.fetchRecommendations(
        latitude: position.latitude,
        longitude: position.longitude,
        type: type,
        minutes: minutes,
        mode: mode,
        stayMinutes: stayMinutes,
        includeVisited: shouldIncludeVisited,
      );
      state = RecommendationLoaded(data);
    } on LocationServiceDisabledException {
      state = const RecommendationLocationServiceDisabled();
    } on LocationPermissionDeniedForeverException {
      state = const RecommendationPermissionDeniedForever();
    } on LocationPermissionDeniedException {
      state = const RecommendationPermissionDenied();
    } catch (e) {
      state = RecommendationError(e.toString());
    }
  }
}
