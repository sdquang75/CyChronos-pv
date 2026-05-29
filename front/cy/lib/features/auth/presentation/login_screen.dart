import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Entry transitions
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

    // Header fades and slides (0 to 1000ms)
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

    // Card fades and slides (300ms delay, ends at 1300ms)
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
    final size = MediaQuery.of(context).size;
    final bool isLargeScreen = size.width > 390 || size.height > 926;

    Widget content = Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFA3E4D7)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(), // overflow-y: scroll
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 48,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // justify-content: space-between
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FadeTransition(
                            opacity: _headerFadeAnim,
                            child: SlideTransition(
                              position: _headerSlideAnim,
                              child: _buildHeader(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FadeTransition(
                            opacity: _cardFadeAnim,
                            child: SlideTransition(
                              position: _cardSlideAnim,
                              child: _buildLoginCard(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '© 2026 CyChronos',
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontFamilyFallback: ['NotoSansJP'],
                              fontSize: 12,
                              color: Color(0x99484553),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
        ),
      ),
    );

    if (isLargeScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFF191C1F),
        body: Center(
          child: Container(
            width: 390,
            height: 926,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: content,
          ),
        ),
      );
    }

    return content;
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/logo.png',
          width: 96,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
        Text(
          'CyChronos',
          style: const TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: Color(0xFF19005C),
            letterSpacing: -0.96,
            height: 56 / 48,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 320,
          child: Text(
            '走行パフォーマンスを追跡し、あらゆる道を征服しましょう。',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontFamilyFallback: ['NotoSansJP'],
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Color(0xFF484553),
              height: 28 / 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
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
              SocialLoginButton(
                icon: SvgPicture.string(_kGoogleSvg),
                label: 'Googleでログイン',
                onPressed: () => GoRouter.of(context).go('/home'),
              ),
              const SizedBox(height: 16),
              SocialLoginButton(
                icon: SvgPicture.string(_kLineSvg),
                label: 'LINEでログイン',
                onPressed: () => GoRouter.of(context).go('/home'),
              ),
              const SizedBox(height: 16),
              SocialLoginButton(
                icon: SvgPicture.string(_kFacebookSvg),
                label: 'Facebookでログイン',
                onPressed: () => GoRouter.of(context).go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _kGoogleSvg = '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
  <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
  <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
  <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
</svg>''';

const _kLineSvg = '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path fill="#06C755" d="M24 10.3c0-4.7-4.7-8.5-10.4-8.5S3.2 5.6 3.2 10.3c0 4.2 3.7 7.7 8.7 8.4l-.6 2.3c-.1.3 0 .6.3.7h.1c.2 0 .5-.1.6-.3l2.6-4.1c4.5-.4 9.1-3.6 9.1-7zm-13.8 3.3c-.2.2-.6.2-.8 0-.2-.2-.2-.6 0-.8l2.2-2.2-2.2-2.2c-.2-.2-.2-.6 0-.8s.6-.2.8 0l2.6 2.6c.2.2.2.6 0 .8l-2.6 2.6zm5.8 0c-.2.2-.6.2-.8 0-.2-.2-.2-.6 0-.8l2.2-2.2-2.2-2.2c-.2-.2-.2-.6 0-.8s.6-.2.8 0l2.6 2.6c.2.2.2.6 0 .8l-2.6 2.6z"/>
</svg>''';

const _kFacebookSvg = '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path fill="#1877F2" d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.469h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.469h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
</svg>''';
