import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'app_icons.dart';
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
                color: const Color(0xFFC9C4D5).withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E0094).withValues(alpha: 0.03),
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
                  backgroundColor: const Color(0xFFF1EBFF),
                  backgroundImage:
                      (user?.photoUrl != null)
                          ? NetworkImage(user!.photoUrl!)
                          : null,
                  child:
                      (user?.photoUrl == null)
                          ? SvgPicture.string(
                            AppIcons.profileTab,
                            width: 44,
                            height: 44,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF19005C),
                              BlendMode.srcIn,
                            ),
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
                    color: Color(0xFF19005C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: const Color(0xFF484553).withValues(alpha: 0.8),
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
              color: Color(0xFF484553),
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
                  color: const Color(0xFFEA4335).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEA4335).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEA4335),
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
                        color: Color(0xFFEA4335),
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
          color: const Color(0xFFC9C4D5).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2A0088), size: 24),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontFamilyFallback: ['NotoSansJP'],
              fontSize: 12,
              color: const Color(0xFF484553).withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Color(0xFF19005C),
            ),
          ),
        ],
      ),
    );
  }
}
