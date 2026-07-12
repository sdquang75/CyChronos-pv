import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cy/core/theme/app_colors.dart';
import 'package:cy/core/widgets/app_screen_frame.dart';
import 'package:cy/core/widgets/app_top_bar.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/providers/auth_provider.dart';

// Preference key shared with any future duration-estimate logic that wants
// to use the rider's self-reported pace instead of a fixed assumption.
const averageSpeedPrefKey = 'average_speed_kmh';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
      final preferences = await SharedPreferences.getInstance();
      final savedSpeed = preferences.getDouble(averageSpeedPrefKey) ?? 18.0;
      if (!mounted) return;
      setState(() {
        _averageSpeedKmh = savedSpeed.clamp(10.0, 30.0).toDouble();
        _isLoadingSpeed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingSpeed = false);
      _showMessage('平均速度を読み込めませんでした', isError: true);
    }
  }

  Future<void> _saveAverageSpeed() async {
    if (_isSavingSpeed) return;
    setState(() => _isSavingSpeed = true);
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setDouble(averageSpeedPrefKey, _averageSpeedKmh);
      if (!mounted) return;
      _showMessage('平均速度を${_averageSpeedKmh.toStringAsFixed(1)} km/hに設定しました');
    } catch (_) {
      if (!mounted) return;
      _showMessage('平均速度を保存できませんでした', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingSpeed = false);
    }
  }

  String get _speedLevel {
    if (_averageSpeedKmh < 15.0) return 'ゆっくり';
    if (_averageSpeedKmh <= 21.0) return '普通';
    return '速い';
  }

  Future<void> _showLogoutDialog() async {
    if (_isLoggingOut) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.logout_rounded, size: 30, color: AppColors.danger),
        ),
        title: const Text(
          'ログアウト',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: AppColors.terracottaDeep,
          ),
        ),
        content: const Text(
          'CyChronosからログアウトしますか？',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontFamilyFallback: ['NotoSansJP'],
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.terracottaBorder.withValues(alpha: 0.65)),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      ),
    );

    if (shouldLogout != true || !mounted) return;
    await _logout();
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await ref.read(authProvider.notifier).signOut();
      if (!mounted) return;
      context.go('/login');
    } catch (_) {
      if (!mounted) return;
      _showMessage('ログアウトに失敗しました。もう一度お試しください。', isError: true);
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'HankenGrotesk', fontFamilyFallback: ['NotoSansJP']),
        ),
        backgroundColor: isError ? AppColors.danger : AppColors.greenPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final userName = user?.name.isNotEmpty == true ? user!.name : 'CyChronos ライダー';
    final userEmail = user?.email ?? '';
    final photoUrl = user?.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return AppScreenFrame(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.bgCool,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopBar(title: 'Settings', fallbackRoute: '/home'),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AccountCard(
                        userName: userName,
                        userEmail: userEmail,
                        photoUrl: photoUrl,
                        hasPhoto: hasPhoto,
                      ),
                      const SizedBox(height: 28),
                      const _SectionTitle(text: 'RIDE SETTINGS'),
                      const SizedBox(height: 12),
                      _isLoadingSpeed
                          ? const _SettingsCard(
                              child: SizedBox(
                                height: 120,
                                child: Center(child: CircularProgressIndicator()),
                              ),
                            )
                          : _SpeedCard(
                              speedKmh: _averageSpeedKmh,
                              speedLevel: _speedLevel,
                              isSaving: _isSavingSpeed,
                              onChanged: (value) => setState(() => _averageSpeedKmh = value),
                              onSave: _saveAverageSpeed,
                            ),
                      const SizedBox(height: 28),
                      const _SectionTitle(text: 'SUPPORT'),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        child: _SettingsMenuRow(
                          icon: Icons.mail_outline_rounded,
                          title: 'お問い合わせ',
                          subtitle: 'ご意見や不具合を送信します',
                          onTap: () => context.push('/contact'),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _SectionTitle(text: 'ACCOUNT'),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        child: _SettingsMenuRow(
                          icon: Icons.logout_rounded,
                          iconColor: AppColors.danger,
                          titleColor: AppColors.danger,
                          title: 'ログアウト',
                          subtitle: '現在のアカウントからログアウトします',
                          trailing: _isLoggingOut
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: AppColors.danger,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.userName,
    required this.userEmail,
    required this.photoUrl,
    required this.hasPhoto,
  });

  final String userName;
  final String userEmail;
  final String? photoUrl;
  final bool hasPhoto;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.terracottaChipBg,
            backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
            child: hasPhoto
                ? null
                : const Icon(Icons.person_rounded, size: 36, color: AppColors.terracottaDeep),
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
                    color: AppColors.terracottaDeep,
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
                      color: AppColors.textSecondary,
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
}

class _SpeedCard extends StatelessWidget {
  const _SpeedCard({
    required this.speedKmh,
    required this.speedLevel,
    required this.isSaving,
    required this.onChanged,
    required this.onSave,
  });

  final double speedKmh;
  final String speedLevel;
  final bool isSaving;
  final ValueChanged<double> onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.terracottaChipBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.speed_rounded, size: 24, color: AppColors.terracottaDeep),
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
                        color: AppColors.terracottaDeep,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '目的地までの所要時間計算に使用します',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontFamilyFallback: ['NotoSansJP'],
                        fontSize: 12,
                        color: AppColors.textSecondary,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.terracottaChipBg,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: AppColors.terracottaDeep.withValues(alpha: 0.15)),
                ),
                child: Text(
                  speedLevel,
                  style: const TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontFamilyFallback: ['NotoSansJP'],
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.terracottaDeep,
                  ),
                ),
              ),
              Text(
                '${speedKmh.toStringAsFixed(1)} km/h',
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.terracottaDeep,
                ),
              ),
            ],
          ),
          Slider(
            value: speedKmh,
            min: 10.0,
            max: 30.0,
            divisions: 40,
            activeColor: AppColors.terracottaDeep,
            inactiveColor: AppColors.terracottaBorder.withValues(alpha: 0.55),
            onChanged: onChanged,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '10 km/h',
                  style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  '30 km/h',
                  style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: isSaving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.terracottaDeep,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.terracottaDeep.withValues(alpha: 0.55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: isSaving
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(strokeWidth: 2.3, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 20),
              label: Text(
                isSaving ? '保存しています' : '平均速度を保存',
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
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.terracottaBorder.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.terracottaCardShadow.withValues(alpha: 0.04),
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
    this.iconColor = AppColors.terracottaDeep,
    this.titleColor = AppColors.terracottaDeep,
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
        onTap: onTap,
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
                        color: AppColors.textSecondary,
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
