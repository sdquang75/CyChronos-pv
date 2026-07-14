import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>(
  (_) => HistoryRepository(),
);

/// ログイン中ユーザーの走行履歴(完了済みトリップのみ、start_time降順)を取得する
final tripHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated || authState.user.userId == null) {
    return const [];
  }

  final repo = ref.watch(historyRepositoryProvider);
  final trips = await repo.fetchTrips(userId: authState.user.userId!);

  // 完了していないトリップ(進行中など)は距離・時間が確定していないので一覧に出さない
  return trips.where((trip) => trip['status'] == 'completed').toList();
});
