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
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/settings_service.dart';

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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              size: 30,
              color: AppColors.error,
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
                      side: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.65),
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
                      backgroundColor: AppColors.error,
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
    showDialog<void>(
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
            'CyChronosは、最適なサイクリングルートの提案、移動中の音声案内、および走行ログの記録のために現在地情報を取得します。\n\n'
            '【外部サービスとの連携】\n'
            'ルート計算およびスポット情報検索のため、MapboxおよびGoogle Maps PlatformのAPIを利用しています。第三者へ個人を特定可能な情報が提供されることはありません。\n\n'
            '【走行データの保護】\n'
            'ユーザーの走行履歴および座標データは暗号化通信により保護され、本人のアカウント管理下でのみ閲覧・削除が可能です。',
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
    final AuthState authState = ref.watch(authProvider);
    final SettingsState settings = ref.watch(settingsProvider);

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
            24,
            24,
            24,
            40 + AppBottomNavigation.barHeightFor(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('設定', style: AppTypography.pageTitle),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'アカウントや走行時のナビゲーションを管理できます。',
                style: AppTypography.pageSubtitle,
              ),

              const SizedBox(height: AppSpacing.xxl + 4),

              // アカウント情報カード
              _buildAccountCard(
                userName: userName,
                userEmail: userEmail,
                photoUrl: photoUrl,
                hasPhoto: hasPhoto,
              ),

              const SizedBox(height: AppSpacing.xxl + 4),

              // ナビゲーション設定
              const Text('ナビゲーション設定', style: AppTypography.sectionLabel),
              const SizedBox(height: AppSpacing.md),
              _buildNavigationCard(settings),

              const SizedBox(height: AppSpacing.xxl + 4),

              // 地図表示設定
              const Text('地図表示設定', style: AppTypography.sectionLabel),
              const SizedBox(height: AppSpacing.md),
              _buildMapCard(settings),

              const SizedBox(height: AppSpacing.xxl + 4),

              // ストレージ & サポート
              const Text('サポート & ストレージ', style: AppTypography.sectionLabel),
              const SizedBox(height: AppSpacing.md),
              _buildSupportAndStorageCard(),

              const SizedBox(height: AppSpacing.xxl + 4),

              // アプリ情報
              const Text('アプリ情報', style: AppTypography.sectionLabel),
              const SizedBox(height: AppSpacing.md),
              _buildAboutCard(),

              const SizedBox(height: AppSpacing.xxl + 4),

              // アカウント操作
              const Text('アカウント', style: AppTypography.sectionLabel),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: EdgeInsets.zero,
                borderRadius: 24,
                clipBehavior: Clip.antiAlias,
                child: _SettingsMenuRow(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.error,
                  title: 'ログアウト',
                  titleColor: AppColors.error,
                  subtitle: '現在のアカウントからログアウトします',
                  trailing: _isLoggingOut
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.accentBg,
            backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
            child: hasPhoto
                ? null
                : const Icon(
                    Icons.person_rounded,
                    size: 36,
                    color: AppColors.primary,
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
                    color: AppColors.primary,
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

  Widget _buildNavigationCard(SettingsState settings) {
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _SettingsSwitchRow(
            icon: Icons.volume_up_rounded,
            title: '音声案内',
            subtitle: '走行中の交差点や曲がり角で音声案内を再生',
            value: settings.voiceGuidanceEnabled,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setVoiceGuidance(val);
            },
          ),
          const Divider(height: 1, indent: 68, endIndent: 20),
          _SettingsSwitchRow(
            icon: Icons.stay_current_portrait_rounded,
            title: '画面の常時点灯',
            subtitle: 'ナビゲーション中に画面がスリープするのを防止',
            value: settings.keepScreenAwake,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setKeepScreenAwake(val);
            },
          ),
          const Divider(height: 1, indent: 68, endIndent: 20),
          _SettingsSwitchRow(
            icon: Icons.alt_route_rounded,
            title: '自動リルート',
            subtitle: 'コースを外れたときに自動で新しいルートを再検索',
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
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.layers_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '地図タイプ',
                      style: TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontFamilyFallback: ['NotoSansJP'],
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Google Mapsの表示スタイルを選択します',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontFamilyFallback: ['NotoSansJP'],
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: types.map((item) {
              final key = item['key'] as String;
              final label = item['label'] as String;
              final icon = item['icon'] as IconData;
              final isSelected = settings.mapTypeKey == key;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(settingsProvider.notifier).setMapType(key);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.accentBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border.withValues(alpha: 0.5),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
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
                          const SizedBox(height: 6),
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
            title: 'お問い合わせ',
            subtitle: 'ご意見や不具合を送信します',
            onTap: () => context.push('/contact'),
          ),
          const Divider(height: 1, indent: 68, endIndent: 20),
          _SettingsMenuRow(
            icon: Icons.cleaning_services_rounded,
            title: 'キャッシュを削除',
            subtitle: '一時保存された画像データを解放します',
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
            title: 'オープンソースライセンス',
            subtitle: '使用しているライブラリの権利表記',
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'CyChronos',
                applicationVersion: 'v1.0.0',
                applicationLegalese: '© 2026 CyChronos Team',
              );
            },
          ),
          const Divider(height: 1, indent: 68, endIndent: 20),
          _SettingsMenuRow(
            icon: Icons.privacy_tip_outlined,
            title: '利用規約 & プライバシー',
            subtitle: '位置情報の取り扱いと利用規約',
            onTap: _showPrivacyPolicyDialog,
          ),
          const Divider(height: 1, indent: 68, endIndent: 20),
          const _SettingsMenuRow(
            icon: Icons.info_outline_rounded,
            title: 'バージョン',
            subtitle: 'CyChronos for Mobile',
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

class _SettingsSwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontFamilyFallback: ['NotoSansJP'],
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
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

class _SettingsMenuRow extends StatelessWidget {
  const _SettingsMenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = AppColors.primary,
    this.titleColor = AppColors.primary,
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
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontFamilyFallback: ['NotoSansJP'],
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: iconColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
