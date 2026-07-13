import 'package:flutter/material.dart';
import 'package:cy/core/theme/app_colors.dart';
import 'home_tab_header.dart';

// TAB: ROUTE SEARCH/EXPLORE SCREEN (MOCKUP)
class RouteTabView extends StatelessWidget {
  const RouteTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeTabHeader(title: 'ルート探索', subtitle: '最適なサイクリングパス'),
          const SizedBox(height: 24),
          const _RouteCard(
            title: '海沿いカフェ巡りコース',
            distance: '18.5 km',
            duration: '1時間15分',
            difficulty: '初級',
            tags: ['カフェ', '絶景'],
          ),
          const SizedBox(height: 16),
          const _RouteCard(
            title: '歴史ある寺院と緑の丘ルート',
            distance: '34.2 km',
            duration: '2時間30分',
            difficulty: '中級',
            tags: ['寺院', '自然', 'ヒルクライム'],
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.title,
    required this.distance,
    required this.duration,
    required this.difficulty,
    required this.tags,
  });

  final String title;
  final String distance;
  final String duration;
  final String difficulty;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greenBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'HankenGrotesk',
              fontFamilyFallback: ['NotoSansJP'],
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.greenDeep,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RouteStat(icon: Icons.directions_bike_rounded, label: distance),
              const SizedBox(width: 16),
              _RouteStat(icon: Icons.timer_rounded, label: duration),
              const SizedBox(width: 16),
              _RouteStat(icon: Icons.trending_up_rounded, label: difficulty),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: tags.map((t) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.greenChipBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  t,
                  style: const TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontFamilyFallback: ['NotoSansJP'],
                    fontSize: 12,
                    color: AppColors.greenDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RouteStat extends StatelessWidget {
  const _RouteStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontFamilyFallback: ['NotoSansJP'],
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
