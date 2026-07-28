import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/settings/presentation/contact_screen.dart';

// Bridges Riverpod state changes → GoRouter refresh
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

// 下部タブ(HOME/HISTORY/SETTINGS)はHomeScreen内のIndexedStackに畳み込まれた
// ので、もうgo_routerのトップレベルルートではない。目的地一覧・詳細・
// ルート確認もRideFlowの入れ子Navigatorに畳み込まれたので同様に無くなった。
// go_routerのトップレベルルートに残るのは「認証で出し分けられる画面」
// (splash/login/home)と「/homeの上に被さる独立した画面」(contact)だけ

// 下部タブ(HOME/HISTORY/SETTINGS)はgo()で「置き換え」遷移するため、
// 前後関係のないスライドではなく短いフェードで切り替える
Page<void> _fadeTabPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

// push()で積む詳細系の画面はMaterialPageの標準遷移に任せる。
// テーマ側でpageTransitionsThemeを上書きしていないため、iOS/macOSでは
// 自動的にCupertino風のスライド遷移+エッジスワイプで戻る操作が有効になる
Page<void> _pushPage(GoRouterState state, Widget child) {
  return MaterialPage<void>(key: state.pageKey, child: child);
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthListenable(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: listenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;

      if (authState is AuthAuthenticated && location == '/login') {
        return '/home';
      }

      if (authState is AuthUnauthenticated && location == '/home') {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder:
            (context, state) => _fadeTabPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder:
            (context, state) => _fadeTabPage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder:
            (context, state) => _fadeTabPage(state, const HomeScreen()),
      ),

      // お問い合わせ画面(SettingsタブからNavigatorではなくgo_routerでpush。
      // HomeScreenの/homeページはそのまま裏に残るので、閉じればタブの状態も保たれる)
      GoRoute(
        path: '/contact',
        pageBuilder:
            (context, state) => _pushPage(state, const ContactScreen()),
      ),
    ],
  );
});
