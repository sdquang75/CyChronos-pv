import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/tap_scale.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/settings_service.dart';

/// 設定画面 (Appleのミニマリズム思想に基づく洗練されたSettings).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoggingOut = false;

  Future<void> _showLogoutDialog() async {
    if (_isLoggingOut) return;

    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              size: 28,
              color: AppColors.error,
            ),
          ),
          title: const Text(
            'ログアウト',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontFamilyFallback: ['NotoSansJP'],
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
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
              height: 1.5,
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
                      side: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.65),
                      ),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'キャンセル',
                      style: TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontFamilyFallback: ['NotoSansJP'],
                        fontSize: 14,
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
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'ログアウト',
                      style: TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontFamilyFallback: ['NotoSansJP'],
                        fontSize: 14,
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
      AppToast.show(context, 'ログアウトに失敗しました。もう一度お試しください。', isError: true);
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Future<void> _showClearCacheDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'キャッシュの削除',
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.primary,
          ),
        ),
        content: const Text(
          '一時保存された画像データを削除して端末のストレージを解放します。\n登録データや走行履歴は削除されません。',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final freedMb = ref.read(settingsProvider.notifier).clearImageCache();
      HapticFeedback.lightImpact();
      AppToast.show(context, 'キャッシュを削除しました (約$freedMb MB 解放)');
    }
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '利用規約 & プライバシー',
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.primary,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            '【位置情報の利用について】\n'
            'CyChronosは、最適なサイクリングルートの提案およびナビゲーションのために端末の位置情報を利用します。'
            '走行ログは暗号化され、ご本人の履歴管理と統計分析の目的でのみ使用されます。\n\n'
            '【免責事項】\n'
            '実際の道路交通法、現地の標識・信号に従って安全に走行してください。'
            'アプリの案内による事故・トラブルについては一切の責任を負いかねます。',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);

    final user = authState is AuthAuthenticated ? authState.user : null;
    final String userName =
        user?.name.isNotEmpty == true ? user!.name : 'CyChronos ライダー';
    final String userEmail = user?.email ?? '';
    final String? photoUrl = user?.photoUrl;
    final bool hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgCool,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            40 + AppBottomNavigation.barHeightFor(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Apple-style bold large title
              const Text('設定', style: AppTypography.pageTitle),
              const SizedBox(height: 20),

              // Account Card
              _buildAccountCard(
                userName: userName,
                userEmail: userEmail,
                photoUrl: photoUrl,
                hasPhoto: hasPhoto,
              ),

              const SizedBox(height: 24),

              // Navigation section
              const Text('ナビゲーション設定', style: AppTypography.sectionLabel),
              const SizedBox(height: AppSpacing.sm),
              _buildNavigationCard(settings),

              const SizedBox(height: 24),

              // Map section
              const Text('地図表示設定', style: AppTypography.sectionLabel),
              const SizedBox(height: AppSpacing.sm),
              _buildMapCard(settings),

              const SizedBox(height: 24),

              // Support & Storage
              const Text('サポート & ストレージ', style: AppTypography.sectionLabel),
              const SizedBox(height: AppSpacing.sm),
              _buildSupportAndStorageCard(),

              const SizedBox(height: 24),

              // About
              const Text('アプリ情報', style: AppTypography.sectionLabel),
              const SizedBox(height: AppSpacing.sm),
              _buildAboutCard(),

              const SizedBox(height: 24),

              // Logout
              AppCard(
                padding: EdgeInsets.zero,
                borderRadius: 24,
                clipBehavior: Clip.antiAlias,
                child: _SettingsMenuRow(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.error,
                  iconBgColor: AppColors.error.withValues(alpha: 0.1),
                  title: 'ログアウト',
                  titleColor: AppColors.error,
                  trailing: _isLoggingOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.error,
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
    );
  }

  Widget _buildAccountCard({
    required String userName,
    required String userEmail,
    required String? photoUrl,
    required bool hasPhoto,
  }) {
    return AppCard(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.accentBg,
            backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
            child: hasPhoto
                ? null
                : const Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(width: 14),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                if (userEmail.isNotEmpty) ...[
                  const SizedBox(height: 3),
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

  Widget _buildNavigationCard(SettingsState settings) {
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _SettingsSwitchRow(
            icon: Icons.volume_up_rounded,
            iconBgColor: const Color(0xFF007AFF).withValues(alpha: 0.12),
            iconColor: const Color(0xFF007AFF),
            title: '音声案内',
            value: settings.voiceGuidanceEnabled,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setVoiceGuidance(val);
            },
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _SettingsSwitchRow(
            icon: Icons.stay_current_portrait_rounded,
            iconBgColor: const Color(0xFF34C759).withValues(alpha: 0.12),
            iconColor: const Color(0xFF34C759),
            title: '画面の常時点灯',
            value: settings.keepScreenAwake,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setKeepScreenAwake(val);
            },
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _SettingsSwitchRow(
            icon: Icons.alt_route_rounded,
            iconBgColor: const Color(0xFFFF9500).withValues(alpha: 0.12),
            iconColor: const Color(0xFFFF9500),
            title: '自動リルート',
            value: settings.autoRerouteEnabled,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setAutoReroute(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(SettingsState settings) {
    final types = [
      {'key': 'normal', 'label': '標準', 'icon': Icons.map_outlined},
      {'key': 'satellite', 'label': '衛星写真', 'icon': Icons.satellite_alt_rounded},
      {'key': 'terrain', 'label': '地形', 'icon': Icons.terrain_rounded},
    ];

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '地図タイプ',
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontFamilyFallback: ['NotoSansJP'],
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: types.map((item) {
              final key = item['key'] as String;
              final label = item['label'] as String;
              final icon = item['icon'] as IconData;
              final isSelected = settings.mapTypeKey == key;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(settingsProvider.notifier).setMapType(key);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.bgCool,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border.withValues(alpha: 0.5),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 20,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'HankenGrotesk',
                              fontFamilyFallback: const ['NotoSansJP'],
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportAndStorageCard() {
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _SettingsMenuRow(
            icon: Icons.mail_outline_rounded,
            iconBgColor: const Color(0xFF5856D6).withValues(alpha: 0.12),
            iconColor: const Color(0xFF5856D6),
            title: 'お問い合わせ',
            onTap: () => context.push('/contact'),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _SettingsMenuRow(
            icon: Icons.cleaning_services_rounded,
            iconBgColor: const Color(0xFFFF2D55).withValues(alpha: 0.12),
            iconColor: const Color(0xFFFF2D55),
            title: 'キャッシュを削除',
            onTap: _showClearCacheDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _SettingsMenuRow(
            icon: Icons.description_outlined,
            iconBgColor: AppColors.accentBg,
            iconColor: AppColors.primary,
            title: 'オープンソースライセンス',
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'CyChronos',
                applicationVersion: 'v1.0.0',
                applicationLegalese: '© 2026 CyChronos Team',
              );
            },
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _SettingsMenuRow(
            icon: Icons.privacy_tip_outlined,
            iconBgColor: AppColors.accentBg,
            iconColor: AppColors.primary,
            title: '利用規約 & プライバシー',
            onTap: _showPrivacyPolicyDialog,
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          const _SettingsMenuRow(
            icon: Icons.info_outline_rounded,
            iconBgColor: AppColors.accentBg,
            iconColor: AppColors.primary,
            title: 'バージョン',
            trailing: Text(
              'v1.0.0 (42)',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            onTap: null,
          ),
        ],
      ),
    );
  }
}

// Apple iOS-style clean switch row (zero cluttered subtext)
class _SettingsSwitchRow extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchRow({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'HankenGrotesk',
                fontFamilyFallback: ['NotoSansJP'],
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.primary,
            onChanged: (newVal) {
              HapticFeedback.lightImpact();
              onChanged(newVal);
            },
          ),
        ],
      ),
    );
  }
}

// Apple iOS-style clean menu row with chevron (zero cluttered subtext)
class _SettingsMenuRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final String title;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsMenuRow({
    required this.icon,
    this.iconColor,
    this.iconBgColor,
    required this.title,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconBgColor =
        iconBgColor ?? AppColors.accentBg;
    final effectiveIconColor =
        iconColor ?? AppColors.primary;

    return TapScale(
      onTap: onTap ?? () {},
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: effectiveIconBgColor,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontFamilyFallback: const ['NotoSansJP'],
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? AppColors.primary,
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
