/// 走行履歴一覧(GET /api/trips)の取得状態
sealed class HistoryState {
  const HistoryState();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryLoaded extends HistoryState {
  final List<Map<String, dynamic>> trips;

  const HistoryLoaded(this.trips);
}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError(this.message);
}
