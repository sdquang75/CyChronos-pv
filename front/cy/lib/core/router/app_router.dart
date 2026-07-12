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
    ref.listen<AuthState>(
      authProvider,
      (_, __) => notifyListeners(),
    );
  }
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
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      ),

      // 走行履歴画面
      GoRoute(
        path: '/history',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HistoryScreen(),
          transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      // 設定画面
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
          transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      // お問い合わせ画面
      GoRoute(
        path: '/contact',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ContactScreen(),
          transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/detil',
        pageBuilder: (context, state) {
          // 一覧画面から渡された目的地1件分
          // (/api/suggest の places の1要素)を受け取る
          final destination = state.extra is Map
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

          return CustomTransitionPage(
            key: state.pageKey,
            // 受け取ったデータを詳細画面へ渡す
            // 欠けている項目は詳細画面側で「--」等を表示
            child: DetilScreen(
              name: destination['name']?.toString() ?? '',
              address: destination['address']?.toString() ?? '',
              genre: destination['genre']?.toString() ?? '',
              imageUrl: imageUrl,
              durationSec: durationSec?.round(),
              distanceMeter: distanceM?.round(),
              rating: rating?.toDouble(),
            ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          );
        },
      ),
      GoRoute(
        path: '/destination',
        pageBuilder: (context, state) {
          // ホーム画面から候補一覧と
          // 検索に使った空き時間(分)を受け取る
          final extraMap = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : <String, dynamic>{};

          final places =
              extraMap['places'] as List<dynamic>? ?? [];

          final minutes = extraMap['minutes'] as int?;

          return CustomTransitionPage(
            key: state.pageKey,
            child: DestinationListScreen(
              places: places,
              minutes: minutes,
            ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          );
        },
      ),
      GoRoute(
        path: '/route_confirm',
        pageBuilder: (context, state) {
          // 1. ルート確認画面に渡すデータを取得
          final extraMap =
              state.extra as Map<String, dynamic>? ?? {};

          final durationSec =
              extraMap['durationSec'] as int? ?? 0;

          final distanceMeter =
              extraMap['distanceMeter'] as int? ?? 0;

          return CustomTransitionPage(
            key: state.pageKey,
            // 2. ルート確認画面にデータを渡す
            child: RouteConfirmScreen(
              durationSec: durationSec,
              distanceMeter: distanceMeter,
            ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          );
        },
      ),
    ],
  );
});