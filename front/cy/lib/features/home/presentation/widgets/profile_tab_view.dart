import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cy/core/theme/app_colors.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../settings/presentation/settings_screen.dart' show averageSpeedPrefKey;
import 'home_tab_header.dart';

// TAB: SETTINGS (アカウント情報 + 各種設定を直接表示。以前は「設定」ボタンから
// 別画面に遷移していたが、タブ内でそのまま設定できるようにインライン化した)
class ProfileTabView extends ConsumerStatefulWidget {
  const ProfileTabView({super.key});

  @override
  ConsumerState<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends ConsumerState<ProfileTabView> {
  double _averageSpeedKmh = 18.0;
  bool _isLoadingSpeed = true;
  bool _isSavingSpeed = false;

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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeTabHeader(title: '設定', subtitle: 'アカウントとアプリの設定'),
          const SizedBox(height: 32),

          // User Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.terracottaBorder.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.terracottaShadow.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar: Google photo or fallback SVG
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.terracottaChipBg,
                  backgroundImage: (user?.photoUrl != null)
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: (user?.photoUrl == null)
                      ? const Icon(
                          Icons.person_rounded,
                          size: 44,
                          color: AppColors.terracottaDeep,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name.isNotEmpty == true ? user!.name : 'CyChronos ライダー',
                  style: const TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontFamilyFallback: ['NotoSansJP'],
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: AppColors.terracottaDeep,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Ride Settings
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

          // Support
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

          // Account / Logout
          const _SectionTitle(text: 'ACCOUNT'),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => ref.read(authProvider.notifier).signOut(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: AppColors.danger,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'ログアウト',
                      style: TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontFamilyFallback: ['NotoSansJP'],
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
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
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.terracottaBorder.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.terracottaShadow.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
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

class _SettingsMenuRow extends StatelessWidget {
  const _SettingsMenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

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
                  color: AppColors.terracottaDeep.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.terracottaDeep, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontFamilyFallback: ['NotoSansJP'],
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.terracottaDeep,
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
              const Icon(Icons.chevron_right_rounded, color: AppColors.terracottaDeep, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}
