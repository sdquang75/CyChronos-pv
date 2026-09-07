import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/history_repository.dart';
import '../../domain/history_state.dart';

final historyRepositoryProvider = Provider<HistoryRepository>(
  (_) => HistoryRepository(),
);

/// HomeScreen(IndexedStackシェル)がHISTORYタブを表示するたびに再取得する
/// のではなく、アプリ全体で1つだけ持つ状態にしている。こうすることで、
/// ルート確認画面でトリップを終了した直後にloadTrips()を呼ぶだけで、
/// HISTORYタブが裏に常駐したままでもサーバー側の最新状態を反映できる
/// (取得元は常にGET /api/trips=サーバー。ローカルに書き足したりはしない)
final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>(
  (ref) {
    final notifier = HistoryNotifier(ref);
    // ログイン完了やセッション復帰時に自動で最新の履歴をサーバーから取得する
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        notifier.loadTrips();
      }
    });
    return notifier;
  },
);

class HistoryNotifier extends StateNotifier<HistoryState> {
  final Ref _ref;

  HistoryNotifier(this._ref) : super(const HistoryLoading()) {
    loadTrips();
  }

  /// ログイン中ユーザーの履歴一覧をサーバーから取り直す
  Future<void> loadTrips() async {
    final authState = _ref.read(authProvider);
    final userId =
        authState is AuthAuthenticated ? authState.user.userId : null;
    if (userId == null) {
      // 未ログイン、またはバックエンド未接続でuser_idが取れていない
      state = const HistoryError('ユーザー情報を取得できませんでした。再度ログインしてください。');
      return;
    }

    // すでにデータがある場合はスピナーで画面を白飛びさせず、裏で静かに最新化する(Apple Optimistic UX)
    if (state is! HistoryLoaded) {
      state = const HistoryLoading();
    }
    try {
      final trips = await _ref
          .read(historyRepositoryProvider)
          .fetchTrips(userId: userId);
      state = HistoryLoaded(trips);
    } catch (_) {
      if (state is! HistoryLoaded) {
        state = const HistoryError('履歴を取得できませんでした。通信環境をご確認のうえ、もう一度お試しください。');
      }
    }
  }

  /// 指定したトリップを論理削除し、一覧を最新化する
  Future<bool> deleteTrip({required int tripId}) async {
    final authState = _ref.read(authProvider);
    final userId =
        authState is AuthAuthenticated ? authState.user.userId : null;
    if (userId == null) return false;

    // 即座に一覧から消してUIの反応を最速化する(楽観的更新)
    final currentState = state;
    if (currentState is HistoryLoaded) {
      final updatedList = currentState.trips
          .where((trip) => trip['trip_id'] != tripId)
          .toList();
      state = HistoryLoaded(updatedList);
    }

    try {
      await _ref
          .read(historyRepositoryProvider)
          .deleteTrip(userId: userId, tripId: tripId);
      final trips = await _ref
          .read(historyRepositoryProvider)
          .fetchTrips(userId: userId);
      state = HistoryLoaded(trips);
      return true;
    } catch (_) {
      await loadTrips();
      return false;
    }
  }
}
