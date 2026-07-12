import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_bottom_navigation.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/history_repository.dart';

/// 走行履歴画面。
/// back/docs/API.md「2. ログ全件取得」(GET /api/trips)の実データを表示する。
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() =>
      _HistoryScreenState();
}

class _HistoryScreenState
    extends ConsumerState<HistoryScreen> {
  final HistoryRepository _repository =
      HistoryRepository();

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
        _errorMessage =
            'ユーザー情報を取得できませんでした。再度ログインしてください。';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final trips =
          await _repository.fetchTrips(userId: userId);

      if (!mounted) return;

      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            '履歴を取得できませんでした。通信環境をご確認のうえ、もう一度お試しください。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isLargeScreen =
        size.width > 390 || size.height > 1115;

    final Widget content = Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned.fill(
            bottom: AppBottomNavigation.barHeight,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildLogo(),

                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),

                          const SizedBox(height: 20),

                          Expanded(
                            child: _buildBody(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: AppBottomNavigation.barHeight,
            child: AppBottomNavigation(
              current: AppTab.history,
            ),
          ),
        ],
      ),
    );

    // HOME画面と同じPC表示用スマホフレーム
    if (isLargeScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFF191C1F),
        body: Center(
          child: Container(
            width: 390,
            height: 1115,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.4,
                  ),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: content,
          ),
        ),
      );
    }

    return content;
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        20,
      ),
      child: Center(
        child: Image.asset(
          'assets/logo_long.png',
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
        Text(
          'アクティビティ履歴',
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w700,
            fontSize: 28,
            color: Color(0xFF19005C),
            height: 1.25,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'これまでの走行記録',
          style: TextStyle(
            fontFamily: 'Inter',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF484553),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF19005C),
        ),
      );
    }

    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return _HistoryMessageView(
        icon: Icons.error_outline_rounded,
        title: '履歴を表示できません',
        message: errorMessage,
        onRetry: _loadTrips,
      );
    }

    if (_trips.isEmpty) {
      return const _HistoryMessageView(
        icon: Icons.directions_bike_rounded,
        title: '走行記録はまだありません',
        message: 'サイクリングに出かけると、ここに走行記録が表示されます。',
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF19005C),
      onRefresh: _loadTrips,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: 4,
          bottom: 16,
        ),
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
    final name =
        trip['destination_name']?.toString() ?? '';
    return name.isNotEmpty ? name : '目的地未設定';
  }

  // 開始日時を「YYYY/MM/DD」の形にする(端末のタイムゾーンに変換)
  String _dateText() {
    final raw = trip['start_time']?.toString();
    if (raw == null) return '--';

    final dateTime = DateTime.tryParse(raw)?.toLocal();
    if (dateTime == null) return '--';

    final month =
        dateTime.month.toString().padLeft(2, '0');
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
    final minutes = ((total % 3600) ~/ 60)
        .toString()
        .padLeft(2, '0');
    final secs =
        (total % 60).toString().padLeft(2, '0');
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC9C4D5).withValues(
            alpha: 0.35,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E0094).withValues(
              alpha: 0.04,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _titleText(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontFamilyFallback: ['NotoSansJP'],
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF19005C),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _dateText(),
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  color: const Color(0xFF484553)
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
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
            color: const Color(0xFF484553)
                .withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: Color(0xFF191C1F),
          ),
        ),
      ],
    );
  }
}

/// 空状態・エラー状態の共通表示
class _HistoryMessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _HistoryMessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 36,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFC9C4D5).withValues(
              alpha: 0.35,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 42,
              color: const Color(0xFF19005C),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'HankenGrotesk',
                fontFamilyFallback: ['NotoSansJP'],
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF19005C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontFamilyFallback: ['NotoSansJP'],
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: Color(0xFF484553),
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF19005C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                ),
                label: const Text(
                  '再読み込み',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontFamilyFallback: ['NotoSansJP'],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
