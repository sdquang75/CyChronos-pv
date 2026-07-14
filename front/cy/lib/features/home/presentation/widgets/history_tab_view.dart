import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cy/core/theme/app_colors.dart';
import '../../../history/presentation/providers/history_provider.dart';
import 'home_tab_header.dart';

// TAB: HISTORY ACTIVITIES SCREEN(/api/trips から取得した実データを表示)
class HistoryTabView extends ConsumerWidget {
  const HistoryTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripHistoryProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeTabHeader(title: 'アクティビティ履歴', subtitle: 'これまでの走行記録'),
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
          const SizedBox(height: 32),

          tripsAsync.when(
            data: (trips) {
              if (trips.isEmpty) {
                return Text(
                  'まだ走行記録がありません',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontFamilyFallback: const ['NotoSansJP'],
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                );
              }
              return Column(
                children: [
                  for (final trip in trips) ...[
                    _HistoryItem(
                      title:
                          (trip['destination_name'] as String?)?.isNotEmpty ==
                              true
                          ? trip['destination_name'] as String
                          : 'サイクリング',
                      date: _formatDate(trip['start_time']),
                      distance: _formatDistance(trip['total_distance_m']),
                      time: _formatDuration(trip['duration_sec']),
                      speed: _formatSpeed(trip['average_speed_kmh']),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Text(
              '走行記録の取得に失敗しました',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontFamilyFallback: const ['NotoSansJP'],
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(Object? startTime) {
    final parsed = DateTime.tryParse(startTime?.toString() ?? '');
    if (parsed == null) return '-';
    return '${parsed.year}/${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}';
  }

  static String _formatDistance(Object? meters) {
    final value = num.tryParse(meters?.toString() ?? '');
    if (value == null) return '-';
    return '${(value / 1000).toStringAsFixed(1)} km';
  }

  static String _formatDuration(Object? seconds) {
    final value = num.tryParse(seconds?.toString() ?? '');
    if (value == null) return '-';
    final total = value.round();
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final secs = total % 60;
    return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  static String _formatSpeed(Object? kmh) {
    final value = num.tryParse(kmh?.toString() ?? '');
    if (value == null) return '-';
    return '${value.toStringAsFixed(1)} km/h';
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.title,
    required this.date,
    required this.distance,
    required this.time,
    required this.speed,
  });

  final String title;
  final String date;
  final String distance;
  final String time;
  final String speed;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontFamilyFallback: ['NotoSansJP'],
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.greenDeep,
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HistoryStat(label: '距離', value: distance),
              _HistoryStat(label: '時間', value: time),
              _HistoryStat(label: '平均速度', value: speed),
            ],
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
        border: Border.all(color: AppColors.greenBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.greenAccent, size: 24),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontFamilyFallback: const ['NotoSansJP'],
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
              color: AppColors.greenDeep,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontSize: 12,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.greenDeep,
          ),
        ),
      ],
    );
  }
}
