import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cy/core/theme/app_colors.dart';
import 'package:cy/core/widgets/app_screen_frame.dart';
import 'providers/auth_provider.dart';
import '../domain/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn),
    );

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
    );

    _animCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAuth());
  }

  Future<void> _initAuth() async {
    // Chạy song song: đảm bảo splash hiện tối thiểu 3.5s + check session
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 3500)),
      ref.read(authProvider.notifier).checkAuth(),
    ]);

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Scaffold(
      body: Container(
        color: AppColors.bgCool,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.414,
                    colors: [
                      AppColors.terracottaHazeA,
                      Color(0x00E6DEFF),
                    ],
                    stops: [0.0, 0.5],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.414,
                    colors: [
                      AppColors.terracottaHazeC,
                      Color(0x00FCF6FF),
                    ],
                    stops: [0.0, 0.5],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.bottomRight,
                    radius: 1.414,
                    colors: [
                      AppColors.terracottaHazeB,
                      Color(0x00E8DEFF),
                    ],
                    stops: [0.0, 0.5],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.bottomLeft,
                    radius: 1.414,
                    colors: [
                      AppColors.bgCool,
                      Color(0x00F8F9FE),
                    ],
                    stops: [0.0, 0.5],
                  ),
                ),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Temporarily hidden (not deleted) — kittytr.png placeholder.
                      // Image.asset(
                      //   'assets/kittytr.png',
                      //   width: 120,
                      //   height: 120,
                      //   fit: BoxFit.contain,
                      // ),
                      // const SizedBox(height: 24),
                      Text(
                        'CyChronos',
                        style: const TextStyle(
                          fontFamily: 'HankenGrotesk',
                          fontFamilyFallback: ['NotoSansJP'],
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: AppColors.terracottaDeep,
                          letterSpacing: -0.96,
                        ),
                      ),
                      const SizedBox(height: 48),
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.terracottaGlow,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '© 2026 CyChronos',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontFamilyFallback: const ['NotoSansJP'],
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return AppScreenFrame(child: content);
  }
}
