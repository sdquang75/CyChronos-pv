import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/destination/presentation/destination_list_screen.dart';
import '../../features/detil/detil.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/route_confirm/route_confirm.dart';
import '../../features/settings/presentation/contact_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../network/place_photo.dart';

// Bridges Riverpod state changes → GoRouter refresh
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

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

      // 走行履歴画面
      GoRoute(
        path: '/history',
        pageBuilder:
            (context, state) => _fadeTabPage(state, const HistoryScreen()),
      ),

      // 設定画面
      GoRoute(
        path: '/settings',
        pageBuilder:
            (context, state) => _fadeTabPage(state, const SettingsScreen()),
      ),

      // お問い合わせ画面
      GoRoute(
        path: '/contact',
        pageBuilder:
            (context, state) => _pushPage(state, const ContactScreen()),
      ),

      GoRoute(
        path: '/detil',
        pageBuilder: (context, state) {
          // 一覧画面から渡された目的地1件分
          // (/api/suggest の places の1要素)を受け取る
          final destination =
              state.extra is Map
                  ? Map<String, dynamic>.from(state.extra as Map)
                  : <String, dynamic>{};

          // 数値はAPIの都合で int でも double でも来るので
          // num で受けてから変換する
          final durationSec = destination['durationSec'] as num?;
          final distanceM = destination['distanceM'] as num?;
          final rating = destination['rating'] as num?;

          // 写真は photoReference をバックの写真プロキシのURLに変換して渡す。
          // 写真なしのスポットは null になり、
          // 詳細画面側で仮画像が表示される
          final imageUrl = placePhotoUrl(
            destination['photoReference']?.toString(),
          );

          return _pushPage(
            state,
            // 受け取ったデータを詳細画面へ渡す
            // 欠けている項目は詳細画面側で「--」等を表示
            DetilScreen(
              name: destination['name']?.toString() ?? '',
              address: destination['address']?.toString() ?? '',
              genre: destination['genre']?.toString() ?? '',
              imageUrl: imageUrl,
              durationSec: durationSec?.round(), // 所要時間(秒)
              distanceMeter: distanceM?.round(), // 距離(m)
              rating: rating?.toDouble(), // 評価(例: 4.2)
              destination: destination, // ルート確認画面へ引き継ぐ用の元データ
            ),
          );
        },
      ),
      GoRoute(
        path: '/destination',
        pageBuilder: (context, state) {
          // ホーム画面から候補一覧と
          // 検索に使った空き時間(分)を受け取る
          final extraMap =
              state.extra is Map
                  ? Map<String, dynamic>.from(state.extra as Map)
                  : <String, dynamic>{};

          final places = extraMap['places'] as List<dynamic>? ?? [];

          final minutes = extraMap['minutes'] as int?;
          final type = extraMap['type']?.toString() ?? 'cafe';

          return _pushPage(
            state,
            DestinationListScreen(places: places, minutes: minutes, type: type),
          );
        },
      ),
      GoRoute(
        path: '/route_confirm',
        pageBuilder: (context, state) {
          // 詳細画面から渡された目的地1件分のデータを受け取る
          final destination =
              state.extra is Map
                  ? Map<String, dynamic>.from(state.extra as Map)
                  : <String, dynamic>{};

          return _pushPage(
            state,
            // ルート確認画面に目的地データを渡す(現在地とルートは画面側でAPIから取得する)
            RouteConfirmScreen(destination: destination),
          );
        },
      ),
    ],
  );
});
