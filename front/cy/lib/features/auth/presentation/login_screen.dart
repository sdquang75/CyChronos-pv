import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:cy/core/widgets/app_screen_frame.dart';
import 'providers/auth_provider.dart';
import '../domain/auth_state.dart';
import 'widgets/social_login_button.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'ログインに失敗しました。もう一度お試しください。',
              style: TextStyle(fontFamily: 'Inter'),
            ),
            backgroundColor: const Color(0xFF19005C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final isLoading = ref.watch(authProvider) is AuthLoading;

    Widget content = Scaffold(
      body: Container(
        color: const Color(0xFFFDFCF8),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x33D5E8D1), Color(0x00D5E8D1)],
                  ),
                ),
              ),
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
                      const Text(
                        '© 2026 CYCHRONOS',
                        style: TextStyle(
                          fontFamily: 'HankenGrotesk',
                          fontFamilyFallback: ['NotoSansJP'],
                          fontSize: 12,
                          color: Color(0x992E0094),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
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
    );

    return AppScreenFrame(child: content);
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset('assets/logo.png', width: 72, fit: BoxFit.contain),
      ],
    );
  }

  Widget _buildLoginCard(bool isLoading) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 448),
          padding: const EdgeInsets.all(33),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFC4C8C0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1F2687).withValues(alpha: 0.07),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'CyChronos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontFamilyFallback: ['NotoSansJP'],
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8BA88E),
                  letterSpacing: -0.75,
                  height: 36 / 30,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: const SizedBox(
                  width: 280,
                  child: Text(
                    '走行パフォーマンスを追跡し、あらゆる道を征服しましょう。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontFamilyFallback: ['NotoSansJP'],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                      height: 22.75 / 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SocialLoginButton(
                icon: SvgPicture.string(_kGoogleSvg),
                label: 'Googleでログイン',
                isLoading: isLoading,
                onPressed:
                    isLoading
                        ? null
                        : () =>
                            ref.read(authProvider.notifier).signInWithGoogle(),
              ),
              const SizedBox(height: 16),
              SocialLoginButton(
                icon: SvgPicture.string(_kLineSvg),
                label: 'LINEでログイン',
                isLoading: isLoading,
                onPressed:
                    isLoading
                        ? null
                        : () => ref.read(authProvider.notifier).signInWithLine(),
              ),
              const SizedBox(height: 16),
              SocialLoginButton(
                icon: SvgPicture.string(_kFacebookSvg),
                label: 'Facebookでログイン',
                isLoading: isLoading,
                onPressed:
                    isLoading
                        ? null
                        : () =>
                            ref.read(authProvider.notifier).signInWithFacebook(),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      '利用規約',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontFamilyFallback: ['NotoSansJP'],
                        fontSize: 12,
                        color: Color(0xCC64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'プライバシーポリシー',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontFamilyFallback: ['NotoSansJP'],
                        fontSize: 12,
                        color: Color(0xCC64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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

const _kLineSvg =
    '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path fill="#06C755" d="M24 10.3c0-4.7-4.7-8.5-10.4-8.5S3.2 5.6 3.2 10.3c0 4.2 3.7 7.7 8.7 8.4l-.6 2.3c-.1.3 0 .6.3.7h.1c.2 0 .5-.1.6-.3l2.6-4.1c4.5-.4 9.1-3.6 9.1-7zm-13.8 3.3c-.2.2-.6.2-.8 0-.2-.2-.2-.6 0-.8l2.2-2.2-2.2-2.2c-.2-.2-.2-.6 0-.8s.6-.2.8 0l2.6 2.6c.2.2.2.6 0 .8l-2.6 2.6zm5.8 0c-.2.2-.6.2-.8 0-.2-.2-.2-.6 0-.8l2.2-2.2-2.2-2.2c-.2-.2-.2-.6 0-.8s.6-.2.8 0l2.6 2.6c.2.2.2.6 0 .8l-2.6 2.6z"/>
</svg>''';

const _kFacebookSvg =
    '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path fill="#1877F2" d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.469h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.469h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
</svg>''';
