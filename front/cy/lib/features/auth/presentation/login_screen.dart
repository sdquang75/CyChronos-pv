import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import '../domain/auth_state.dart';
import 'widgets/social_login_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_aurora_background.dart';
import '../../../core/widgets/app_screen_frame.dart';
import '../../../core/widgets/app_toast.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _headerFadeAnim;
  late final Animation<Offset> _headerSlideAnim;
  late final Animation<double> _cardFadeAnim;
  late final Animation<Offset> _cardSlideAnim;

  double _mouseX = 0.0;
  double _mouseY = 0.0;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _headerFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 1000 / 1300, curve: Curves.easeOut),
      ),
    );
    _headerSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 1000 / 1300, curve: Curves.easeOut),
      ),
    );

    _cardFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(300 / 1300, 1.0, curve: Curves.easeOut),
      ),
    );
    _cardSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(300 / 1300, 1.0, curve: Curves.easeOut),
      ),
    );

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthAuthenticated) {
        context.go('/home');
      } else if (next is AuthError) {
        AppToast.show(context, next.message, isError: true);
      }
    });

    final isLoading = ref.watch(authProvider) is AuthLoading;

    return AppScreenFrame(
      child: Scaffold(
        body: MouseRegion(
          onHover: (event) {
            setState(() {
              final s = MediaQuery.of(context).size;
              _mouseX = (event.position.dx / s.width) - 0.5;
              _mouseY = (event.position.dy / s.height) - 0.5;
            });
          },
          child: Container(
            color: AppColors.bgCool,
            child: Stack(
              children: [
                const AppAuroraBackground(),
                _GlowBlob(
                  top: -96,
                  left: -96,
                  color: AppColors.gradientStart.withValues(alpha: 0.18),
                  width: 384,
                  height: 384,
                  blur: 100,
                  offsetX: _mouseX * 30,
                  offsetY: _mouseY * 30,
                ),
                _GlowBlob(
                  bottom: -96,
                  right: -96,
                  color: const Color(0xFFE8DEFF).withValues(alpha: 0.18),
                  width: 384,
                  height: 384,
                  blur: 100,
                  offsetX: _mouseX * 60,
                  offsetY: _mouseY * 60,
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 48,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FadeTransition(
                            opacity: _headerFadeAnim,
                            child: SlideTransition(
                              position: _headerSlideAnim,
                              child: _buildHeader(),
                            ),
                          ),
                          const SizedBox(height: 48),
                          FadeTransition(
                            opacity: _cardFadeAnim,
                            child: SlideTransition(
                              position: _cardSlideAnim,
                              child: _buildLoginCard(isLoading),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            '© 2026 CyChronos',
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontFamilyFallback: const ['NotoSansJP'],
                              fontSize: 12,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.6,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset('assets/logo.png', width: 96, fit: BoxFit.contain),
        const SizedBox(height: 16),
        const Text(
          'CyChronos',
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: -0.96,
            height: 56 / 48,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(bool isLoading) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 384),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // サードパーティログインでログイン/新規登録を別ボタンに分けるのは不自然
              // (Google自身が初回かどうかを知っている)なので、ボタンは1つだけ。
              // バックエンド未登録なら自動でアカウントが作られる
              SocialLoginButton(
                icon: SvgPicture.string(_kGoogleSvg),
                label: 'Googleでログイン',
                isLoading: isLoading,
                onPressed:
                    isLoading
                        ? null
                        : () {
                          ref.read(authProvider.notifier).signInWithGoogle();
                        },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double? top, left, bottom, right;
  final Color color;
  final double width;
  final double height;
  final double blur;
  final double offsetX;
  final double offsetY;

  const _GlowBlob({
    this.top,
    this.left,
    this.bottom,
    this.right,
    required this.color,
    this.width = 384,
    this.height = 384,
    this.blur = 100,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top != null ? top! + offsetY : null,
      left: left != null ? left! + offsetX : null,
      bottom: bottom != null ? bottom! - offsetY : null,
      right: right != null ? right! - offsetX : null,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
      ),
    );
  }
}

const _kGoogleSvg =
    '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
  <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
  <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
  <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
</svg>''';
