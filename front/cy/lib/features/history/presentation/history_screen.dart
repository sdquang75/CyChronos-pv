import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/tap_scale.dart';
import '../domain/history_state.dart';
import 'providers/history_provider.dart';
import 'trip_detail_screen.dart';

/// 走行履歴画面 (Appleのミニマリズム思想に基づく洗練されたアクティビティ履歴)。
/// back/docs/API.md「2. ログ全件取得」(GET /api/trips)の実データを表示する。
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppColors.bgCool,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: AppBottomNavigation.barHeightFor(context),
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 18),
                      Expanded(child: _buildBody(ref, historyState)),
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

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'アクティビティ履歴',
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w800,
            fontSize: 32,
            letterSpacing: -0.8,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(WidgetRef ref, HistoryState state) {
    if (state is HistoryLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state is HistoryError) {
      return AppStateView(
        icon: Icons.error_outline_rounded,
        title: '履歴を表示できません',
        message: state.message,
        retryLabel: '再読み込み',
        onRetry: () => ref.read(historyProvider.notifier).loadTrips(),
      );
    }

    final trips = state is HistoryLoaded ? state.trips : const [];
    if (trips.isEmpty) {
      return const AppStateView(
        icon: Icons.directions_bike_rounded,
        title: '走行記録はまだありません',
        message: 'サイクリングに出かけると、ここに走行記録が表示されます。',
      );
    }

    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final nextMonday = monday.add(const Duration(days: 7));

    double weekDistanceM = 0;
    int weekTripCount = 0;
    int weekDurationSec = 0;

    for (final raw in trips) {
      if (raw is! Map<String, dynamic>) continue;
      final startTimeStr = raw['start_time']?.toString();
      if (startTimeStr == null) continue;
      final tripDate = DateTime.tryParse(startTimeStr)?.toLocal();
      if (tripDate != null &&
          !tripDate.isBefore(monday) &&
          tripDate.isBefore(nextMonday)) {
        weekTripCount++;
        final dist = raw['total_distance_m'];
        if (dist is num) weekDistanceM += dist.toDouble();
        final dur = raw['duration_sec'];
        if (dur is num) weekDurationSec += dur.toInt();
      }
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () {
        HapticFeedback.lightImpact();
        return ref.read(historyProvider.notifier).loadTrips();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 2, bottom: 20),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: trips.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _WeeklySummaryCard(
              distanceM: weekDistanceM,
              tripCount: weekTripCount,
              durationSec: weekDurationSec,
            );
          }
          return _TripCard(trip: trips[index - 1] as Map<String, dynamic>);
        },
      ),
    );
  }
}

/// 今週のアクティビティ概要カード (Apple Fitness風の洗練されたウィジェット)
class _WeeklySummaryCard extends StatelessWidget {
  final double distanceM;
  final int tripCount;
  final int durationSec;

  const _WeeklySummaryCard({
    required this.distanceM,
    required this.tripCount,
    required this.durationSec,
  });

  String _formatDuration(int seconds) {
    if (seconds == 0) return '0分';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours == 0) return '$minutes分';
    return '$hours時間$minutes分';
  }

  @override
  Widget build(BuildContext context) {
    final km = (distanceM / 1000).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color(0xFF1B4332),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_bike_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '今週のアクティビティ',
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontFamilyFallback: ['NotoSansJP'],
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatMetric('走行距離', '${km}km'),
              Container(
                width: 1,
                height: 28,
                color: Colors.white.withValues(alpha: 0.18),
              ),
              _buildStatMetric('ライド回数', '$tripCount回'),
              Container(
                width: 1,
                height: 28,
                color: Colors.white.withValues(alpha: 0.18),
              ),
              _buildStatMetric('走行時間', _formatDuration(durationSec)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: const ['NotoSansJP'],
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// トリップ1件分のカード (Apple Minimalism風の整理されたカード)
class _TripCard extends ConsumerWidget {
  final Map<String, dynamic> trip;

  const _TripCard({required this.trip});

  String _titleText() {
    final name = trip['destination_name']?.toString() ?? '';
    return name.isNotEmpty ? name : '目的地未設定';
  }

  String _dateText() {
    final raw = trip['start_time']?.toString();
    if (raw == null) return '--';

    final dateTime = DateTime.tryParse(raw)?.toLocal();
    if (dateTime == null) return '--';

    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}/$month/$day';
  }

  String _distanceText() {
    final meters = trip['total_distance_m'];
    if (meters is! num) return '--';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _durationText() {
    final seconds = trip['duration_sec'];
    if (seconds is! num) return '--';

    final total = seconds.round();
    final hours = total ~/ 3600;
    final minutes = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (total % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  String _speedText() {
    final speed = trip['average_speed_kmh'];
    if (speed is! num) return '--';
    return '${speed.toStringAsFixed(1)} km/h';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripId = (trip['trip_id'] as num).toInt();

    return Dismissible(
      key: ValueKey('trip-$tripId'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        HapticFeedback.lightImpact();
        return showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              '走行記録の削除',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontFamilyFallback: ['NotoSansJP'],
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.primary,
              ),
            ),
            content: const Text(
              'この走行記録を削除しますか？\n削除した記録は元に戻せません。',
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
                  backgroundColor: AppColors.error,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('削除する'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        final success =
            await ref.read(historyProvider.notifier).deleteTrip(tripId: tripId);
        if (context.mounted) {
          if (success) {
            AppToast.show(context, '走行記録を削除しました');
          } else {
            AppToast.show(context, '削除に失敗しました');
          }
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              '削除',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TapScale(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TripDetailScreen(trip: trip),
              ),
            );
          },
          child: AppCard(
            borderRadius: 22,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accentBg,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.directions_bike_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleText(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'HankenGrotesk',
                              fontFamilyFallback: ['NotoSansJP'],
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _dateText(),
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 11.5,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgCool,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem('距離', _distanceText()),
                      _buildStatItem('時間', _durationText()),
                      _buildStatItem('平均速度', _speedText()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: const ['NotoSansJP'],
            fontSize: 11,
            color: AppColors.textSecondary.withValues(alpha: 0.75),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
