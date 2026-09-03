import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/app_toast.dart';
import '../domain/history_state.dart';
import 'providers/history_provider.dart';
import 'trip_detail_screen.dart';

/// 走行履歴画面。
/// back/docs/API.md「2. ログ全件取得」(GET /api/trips)の実データを表示する。
/// 取得状態はhistoryProviderが持つ(HomeScreenのIndexedStackで裏に常駐していても、
/// ルート確認画面でトリップを終えた直後にhistoryProvider側から再取得できるようにするため)
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);

    // AppScreenFrame・下部メニューバーはHomeScreen(IndexedStackシェル)側で
    // 一括して描画されるので、ここでは自分の中身だけを組み立てる
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
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),

                      const SizedBox(height: AppSpacing.xl),

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
        Text('アクティビティ履歴', style: AppTypography.pageTitle),
        SizedBox(height: AppSpacing.sm),
        Text('これまでの走行記録', style: AppTypography.pageSubtitle),
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
        padding: const EdgeInsets.only(top: 4, bottom: 16),
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

/// 今週のアクティビティ(走行距離・回数・時間)を一覧上部にカード表示する
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
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color(0xFF2D6A4F),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.directions_bike_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '今週のアクティビティ',
                style: TextStyle(
                  fontFamilyFallback: ['NotoSansJP'],
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatMetric('走行距離', '${km}km'),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              _buildStatMetric('ライド回数', '$tripCount回'),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withValues(alpha: 0.2),
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
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamilyFallback: const ['NotoSansJP'],
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// トリップ1件分のカード(GET /api/trips の1要素を表示する)
class _TripCard extends ConsumerWidget {
  final Map<String, dynamic> trip;

  const _TripCard({required this.trip});

  // 目的地名。未設定(空文字)のトリップは「目的地未設定」と表示する
  String _titleText() {
    final name = trip['destination_name']?.toString() ?? '';
    return name.isNotEmpty ? name : '目的地未設定';
  }

  // 開始日時を「YYYY/MM/DD」の形にする(端末のタイムゾーンに変換)
  String _dateText() {
    final raw = trip['start_time']?.toString();
    if (raw == null) return '--';

    final dateTime = DateTime.tryParse(raw)?.toLocal();
    if (dateTime == null) return '--';

    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}/$month/$day';
  }

  // 走行距離(total_distance_m)をkm表示にする。未計測は「--」
  String _distanceText() {
    final meters = trip['total_distance_m'];
    if (meters is! num) return '--';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  // 走行時間(duration_sec)を「H:MM:SS」にする。未計測は「--」
  String _durationText() {
    final seconds = trip['duration_sec'];
    if (seconds is! num) return '--';

    final total = seconds.round();
    final hours = total ~/ 3600;
    final minutes = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (total % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  // 平均速度(average_speed_kmh)。未計測は「--」
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            title: const Text('走行記録の削除'),
            content: const Text('この走行記録を削除しますか？\n削除した記録は元に戻せません。'),
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
        margin: const EdgeInsets.only(bottom: 14),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
            SizedBox(width: AppSpacing.sm),
            Text(
              '削除',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 14),
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TripDetailScreen(trip: trip),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _titleText(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardTitle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      _dateText(),
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat('距離', _distanceText()),
                    _buildStat('時間', _durationText()),
                    _buildStat('平均速度', _speedText()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: const ['NotoSansJP'],
            fontSize: 12,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.stat.copyWith(fontSize: 15)),
      ],
    );
  }
}
