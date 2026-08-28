import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/history_repository.dart';

/// 走行履歴画面。
/// back/docs/API.md「2. ログ全件取得」(GET /api/trips)の実データを表示する。
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final HistoryRepository _repository = HistoryRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  /// ログイン中ユーザーの user_id(バックエンド users テーブルのID)を取り出す
  int? _currentUserId() {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return null;
    return authState.user.userId;
  }

  Future<void> _loadTrips() async {
    final userId = _currentUserId();

    if (userId == null) {
      // 未ログイン、またはバックエンド未接続で user_id が取れていない
      setState(() {
        _isLoading = false;
        _errorMessage = 'ユーザー情報を取得できませんでした。再度ログインしてください。';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final trips = await _repository.fetchTrips(userId: userId);

      if (!mounted) return;

      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = '履歴を取得できませんでした。通信環境をご確認のうえ、もう一度お試しください。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              _buildLogo(),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),

                      const SizedBox(height: AppSpacing.xl),

                      Expanded(child: _buildBody()),
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

  // タブのルート画面なので、pushで開く画面(AppTopBar)とは違い
  // ロゴを直接表示する(戻るボタンは不要なため)
  Widget _buildLogo() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.xl,
      ),
      child: Center(
        child: Image(
          image: AssetImage('assets/logo_long.png'),
          width: 200,
          fit: BoxFit.contain,
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return AppStateView(
        icon: Icons.error_outline_rounded,
        title: '履歴を表示できません',
        message: errorMessage,
        retryLabel: '再読み込み',
        onRetry: _loadTrips,
      );
    }

    if (_trips.isEmpty) {
      return const AppStateView(
        icon: Icons.directions_bike_rounded,
        title: '走行記録はまだありません',
        message: 'サイクリングに出かけると、ここに走行記録が表示されます。',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () {
        HapticFeedback.lightImpact();
        return _loadTrips();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: _trips.length,
        itemBuilder: (context, index) {
          return _TripCard(trip: _trips[index]);
        },
      ),
    );
  }
}

/// トリップ1件分のカード(GET /api/trips の1要素を表示する)
class _TripCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
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
