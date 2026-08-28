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
  (ref) => HistoryNotifier(ref),
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

    state = const HistoryLoading();
    try {
      final trips = await _ref
          .read(historyRepositoryProvider)
          .fetchTrips(userId: userId);
      state = HistoryLoaded(trips);
    } catch (_) {
      state = const HistoryError('履歴を取得できませんでした。通信環境をご確認のうえ、もう一度お試しください。');
    }
  }
}
