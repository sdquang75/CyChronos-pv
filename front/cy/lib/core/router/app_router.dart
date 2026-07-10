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
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DetilScreen(),
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
        path: '/destination',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DestinationListScreen(),
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
        path: '/route_confirm',
        pageBuilder: (context, state) {
          // Optional data forwarded from DestinationListScreen when a card's
          // "ルートを確認する" CTA is tapped.
          final extra = state.extra;
          final data = extra is Map<String, dynamic> ? extra : null;

          return CustomTransitionPage(
            key: state.pageKey,
            child: RouteConfirmScreen(
              destinationName: data?['destinationName'] as String? ?? 'ABC park',
              distanceText: data?['distanceText'] as String? ?? '12.4 km',
              durationText: data?['durationText'] as String? ?? '45 min',
              thumbnailAsset:
                  data?['thumbnailAsset'] as String? ?? 'assets/testimage.png',
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