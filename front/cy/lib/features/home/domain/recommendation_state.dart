sealed class RecommendationState {
  const RecommendationState();
}

class RecommendationInitial extends RecommendationState {
  const RecommendationInitial();
}

// Requesting/checking location permission, before any network call
class RecommendationLocating extends RecommendationState {
  const RecommendationLocating();
}

// Coordinates obtained, request sent to backend, awaiting response
class RecommendationLoading extends RecommendationState {
  const RecommendationLoading();
}

// Raw response body from backend. Shape TBD by backend team.
class RecommendationLoaded extends RecommendationState {
  final dynamic data;

  const RecommendationLoaded(this.data);
}

class RecommendationLocationServiceDisabled extends RecommendationState {
  const RecommendationLocationServiceDisabled();
}

class RecommendationPermissionDenied extends RecommendationState {
  const RecommendationPermissionDenied();
}

class RecommendationPermissionDeniedForever extends RecommendationState {
  const RecommendationPermissionDeniedForever();
}

class RecommendationError extends RecommendationState {
  final String message;

  const RecommendationError(this.message);
}
