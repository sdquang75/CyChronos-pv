import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cy/core/theme/app_colors.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'home_tab_header.dart';

// TAB: USER PROFILE SCREEN WITH LOGOUT BUTTON
class ProfileTabView extends ConsumerWidget {
  const ProfileTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeTabHeader(title: 'プロフィール', subtitle: 'ユーザーアカウント設定'),
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
          const SizedBox(height: 24),

          // Statistics Grid
          const Text(
            'STATISTICS',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w500,
              fontSize: 13,
              letterSpacing: 0.7,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: '総走行距離',
                  value: '83.2 km',
                  icon: Icons.directions_bike_rounded,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: '総走行時間',
                  value: '4.5 hrs',
                  icon: Icons.timer_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Settings Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/settings'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.terracottaBorder.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.settings_rounded,
                      color: AppColors.terracottaDeep,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      '設定',
                      style: TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontFamilyFallback: ['NotoSansJP'],
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.terracottaDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Logout Button
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.terracottaBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.terracottaAccent, size: 24),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontFamilyFallback: ['NotoSansJP'],
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppColors.terracottaDeep,
            ),
          ),
        ],
      ),
    );
  }
}
