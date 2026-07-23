//settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_screen_frame.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const Color backgroundColor = Color(0xFFF8F9FE);
  static const Color primaryColor = Color(0xFF19005C);
  static const Color secondaryColor = Color(0xFF484553);
  static const Color borderColor = Color(0xFFC9C4D5);
  static const Color accentBackgroundColor = Color(0xFFF1EBFF);
  static const Color logoutColor = Color(0xFFBA1A1A);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const String _averageSpeedKey = 'average_speed_kmh';

  double _averageSpeedKmh = 18.0;

  bool _isLoadingSpeed = true;
  bool _isSavingSpeed = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadAverageSpeed();
  }

  Future<void> _loadAverageSpeed() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      final double savedSpeed = preferences.getDouble(_averageSpeedKey) ?? 18.0;

      if (!mounted) {
        return;
      }

      setState(() {
        _averageSpeedKmh = savedSpeed.clamp(10.0, 30.0).toDouble();
        _isLoadingSpeed = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingSpeed = false;
      });

      _showMessage('平均速度を読み込めませんでした', isError: true);
    }
  }

  Future<void> _saveAverageSpeed() async {
    if (_isSavingSpeed) {
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      _isSavingSpeed = true;
    });

    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      await preferences.setDouble(_averageSpeedKey, _averageSpeedKmh);

      if (!mounted) {
        return;
      }

      _showMessage(
        '平均速度を'
        '${_averageSpeedKmh.toStringAsFixed(1)} km/h'
        'に設定しました',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('平均速度を保存できませんでした', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSavingSpeed = false;
        });
      }
    }
  }

  String get _speedLevel {
    if (_averageSpeedKmh < 15.0) {
      return 'ゆっくり';
    }

    if (_averageSpeedKmh <= 21.0) {
      return '普通';
    }

    return '速い';
  }

  Future<void> _showLogoutDialog() async {
    if (_isLoggingOut) {
      return;
    }

    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: SettingsScreen.logoutColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              size: 30,
              color: SettingsScreen.logoutColor,
            ),
          ),
          title: const Text(
            'ログアウト',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontFamilyFallback: ['NotoSansJP'],
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: SettingsScreen.primaryColor,
            ),
          ),
          content: const Text(
            'CyChronosからログアウトしますか？',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontFamilyFallback: ['NotoSansJP'],
              fontSize: 14,
              color: SettingsScreen.secondaryColor,
              height: 1.6,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SettingsScreen.secondaryColor,
                      side: BorderSide(
                        color: SettingsScreen.borderColor.withValues(
                          alpha: 0.65,
                        ),
                      ),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'キャンセル',
                      style: TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontFamilyFallback: ['NotoSansJP'],
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(dialogContext).pop(true);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: SettingsScreen.logoutColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'ログアウト',
                      style: TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontFamilyFallback: ['NotoSansJP'],
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    await _logout();
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await ref.read(authProvider.notifier).signOut();

      if (!mounted) {
        return;
      }

      context.go('/login');
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('ログアウトに失敗しました。もう一度お試しください。', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
          ),
        ),
        backgroundColor:
            isError ? SettingsScreen.logoutColor : const Color(0xFF2A0088),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authProvider);

    final user = authState is AuthAuthenticated ? authState.user : null;

    final String userName =
        user?.name.isNotEmpty == true ? user!.name : 'CyChronos ライダー';

    final String userEmail = user?.email ?? '';

    final String? photoUrl = user?.photoUrl;

    final bool hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return AppScreenFrame(
      child: Scaffold(
        backgroundColor: SettingsScreen.backgroundColor,
        body: Stack(
          children: [
            Positioned.fill(
              bottom: AppBottomNavigation.barHeight,
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLogo(),

                      const SizedBox(height: 32),

                      const Text(
                        '設定',
                        style: TextStyle(
                          fontFamily: 'HankenGrotesk',
                          fontFamilyFallback: ['NotoSansJP'],
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: SettingsScreen.primaryColor,
                          height: 1.25,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'アカウントや走行時の設定を管理できます。',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontFamilyFallback: ['NotoSansJP'],
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: SettingsScreen.secondaryColor,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 28),

                      _buildAccountCard(
                        userName: userName,
                        userEmail: userEmail,
                        photoUrl: photoUrl,
                        hasPhoto: hasPhoto,
                      ),

                      const SizedBox(height: 28),

                      const _SectionTitle(text: 'RIDE SETTINGS'),

                      const SizedBox(height: 12),

                      _buildSpeedCard(),

                      const SizedBox(height: 28),

                      const _SectionTitle(text: 'SUPPORT'),

                      const SizedBox(height: 12),

                      _SettingsCard(
                        child: _SettingsMenuRow(
                          icon: Icons.mail_outline_rounded,
                          title: 'お問い合わせ',
                          subtitle: 'ご意見や不具合を送信します',
                          onTap: () {
                            context.push('/contact');
                          },
                        ),
                      ),

                      const SizedBox(height: 28),

                      const _SectionTitle(text: 'ACCOUNT'),

                      const SizedBox(height: 12),

                      _SettingsCard(
                        child: _SettingsMenuRow(
                          icon: Icons.logout_rounded,
                          iconColor: SettingsScreen.logoutColor,
                          title: 'ログアウト',
                          titleColor: SettingsScreen.logoutColor,
                          subtitle: '現在のアカウントからログアウトします',
                          trailing:
                              _isLoggingOut
                                  ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: SettingsScreen.logoutColor,
                                    ),
                                  )
                                  : null,
                          onTap: _isLoggingOut ? null : _showLogoutDialog,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 共通の画面下部メニューバー(HOME・HISTORY・SETTINGS)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: AppBottomNavigation.barHeight,
              child: AppBottomNavigation(current: AppTab.settings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Image.asset(
        'assets/logo_long.png',
        width: 200,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildAccountCard({
    required String userName,
    required String userEmail,
    required String? photoUrl,
    required bool hasPhoto,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: SettingsScreen.borderColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E0094).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: SettingsScreen.accentBackgroundColor,
            backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
            child:
                hasPhoto
                    ? null
                    : const Icon(
                      Icons.person_rounded,
                      size: 36,
                      color: SettingsScreen.primaryColor,
                    ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontFamilyFallback: ['NotoSansJP'],
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: SettingsScreen.primaryColor,
                  ),
                ),

                if (userEmail.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    userEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontFamilyFallback: ['NotoSansJP'],
                      fontSize: 13,
                      color: SettingsScreen.secondaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: SettingsScreen.borderColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E0094).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child:
          _isLoadingSpeed
              ? const SizedBox(
                height: 150,
                child: Center(
                  child: CircularProgressIndicator(
                    color: SettingsScreen.primaryColor,
                  ),
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: SettingsScreen.accentBackgroundColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.speed_rounded,
                          size: 24,
                          color: SettingsScreen.primaryColor,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '平均速度',
                              style: TextStyle(
                                fontFamily: 'HankenGrotesk',
                                fontFamilyFallback: ['NotoSansJP'],
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: SettingsScreen.primaryColor,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              '目的地までの所要時間計算に使用します',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontFamilyFallback: ['NotoSansJP'],
                                fontSize: 12,
                                color: SettingsScreen.secondaryColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: SettingsScreen.accentBackgroundColor,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: SettingsScreen.primaryColor.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                        child: Text(
                          _speedLevel,
                          style: const TextStyle(
                            fontFamily: 'HankenGrotesk',
                            fontFamilyFallback: ['NotoSansJP'],
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: SettingsScreen.primaryColor,
                          ),
                        ),
                      ),

                      Text(
                        '${_averageSpeedKmh.toStringAsFixed(1)} km/h',
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: SettingsScreen.primaryColor,
                        ),
                      ),
                    ],
                  ),

                  Slider(
                    value: _averageSpeedKmh,
                    min: 10.0,
                    max: 30.0,
                    divisions: 40,
                    activeColor: SettingsScreen.primaryColor,
                    inactiveColor: SettingsScreen.borderColor.withValues(
                      alpha: 0.55,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _averageSpeedKmh = value;
                      });
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '10 km/h',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            color: SettingsScreen.secondaryColor,
                          ),
                        ),
                        Text(
                          '30 km/h',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            color: SettingsScreen.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _isSavingSpeed ? null : _saveAverageSpeed,
                      style: FilledButton.styleFrom(
                        backgroundColor: SettingsScreen.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: SettingsScreen.primaryColor
                            .withValues(alpha: 0.55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon:
                          _isSavingSpeed
                              ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.3,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.check_rounded, size: 20),
                      label: Text(
                        _isSavingSpeed ? '保存しています' : '平均速度を保存',
                        style: const TextStyle(
                          fontFamily: 'HankenGrotesk',
                          fontFamilyFallback: ['NotoSansJP'],
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.7,
        color: SettingsScreen.secondaryColor,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: SettingsScreen.borderColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E0094).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SettingsMenuRow extends StatelessWidget {
  const _SettingsMenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = SettingsScreen.primaryColor,
    this.titleColor = SettingsScreen.primaryColor,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color titleColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            onTap == null
                ? null
                : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 23),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontFamilyFallback: const ['NotoSansJP'],
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontFamilyFallback: ['NotoSansJP'],
                        fontSize: 12,
                        color: SettingsScreen.secondaryColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              if (trailing != null)
                trailing!
              else
                Icon(Icons.chevron_right_rounded, color: iconColor, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}
