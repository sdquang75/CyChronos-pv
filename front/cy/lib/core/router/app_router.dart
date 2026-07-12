import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/destination/presentation/destination_list_screen.dart';
import '../../features/detil/detil.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/route_confirm/route_confirm.dart';
import '../network/api_client.dart';


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
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      ),
      GoRoute(
        path: '/detil',
        pageBuilder: (context, state) {
          // 一覧画面から渡された目的地1件分(/api/suggest の places の1要素)を受け取る
          final destination = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : <String, dynamic>{};

          // 数値はAPIの都合で int でも double でも来るので num で受けてから変換する
          final durationSec = destination['durationSec'] as num?;
          final distanceM = destination['distanceM'] as num?;
          final rating = destination['rating'] as num?;

          // 写真は photoReference をバックの写真プロキシ(/api/maps/photo)のURLに変換して渡す。
          // バック未実装・写真なしのスポットは null になり、詳細画面側で仮画像が表示される
          final photoReference = destination['photoReference']?.toString();
          final imageUrl = (photoReference == null || photoReference.isEmpty)
              ? null
              : Uri.parse(ApiClient.instance.options.baseUrl)
                  .replace(
                    path: '/api/maps/photo',
                    queryParameters: {
                      'photoReference': photoReference,
                      'maxwidth': '800',
                    },
                  )
                  .toString();

          return CustomTransitionPage(
            key: state.pageKey,
            // 受け取ったデータを詳細画面へ渡す(欠けている項目は詳細画面側で「--」等を表示)
            child: DetilScreen(
              name: destination['name']?.toString() ?? '',
              address: destination['address']?.toString() ?? '',
              genre: destination['genre']?.toString() ?? '',
              imageUrl: imageUrl,
              durationSec: durationSec?.round(), // 所要時間(秒)
              distanceMeter: distanceM?.round(), // 距離(m)
              rating: rating?.toDouble(), // 評価(例: 4.2)
              // 紹介文はまだAPIに無いので渡さない(画面側が仮テキストを表示する)
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
          final places = state.extra as List<dynamic>? ?? [];

          return CustomTransitionPage(
            key: state.pageKey,
            child: DestinationListScreen(places: places),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
        pageBuilder: (context, state){
          // 1. ルート確認画面に渡すデータを取得
          final extraMap = state.extra as Map<String, dynamic>? ?? {};
          final durationSec = extraMap['durationSec'] as int? ?? 0;
          final distanceMeter = extraMap['distanceMeter'] as int? ?? 0;

          return CustomTransitionPage(
            key: state.pageKey,
            // 2. ルート確認画面にデータを渡す
            child: RouteConfirmScreen(
              durationSec: durationSec,
              distanceMeter: distanceMeter,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
