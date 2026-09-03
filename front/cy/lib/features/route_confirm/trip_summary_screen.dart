import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/widgets/app_button.dart';

/// 走行終了後に出す完了画面。以前はトースト1本(「案内を終了しました」等)で
/// 済ませていたが、達成感が伝わらないので専用の画面に差し替えた。
/// 距離・時間・平均速度は現状すべて推定値(Mapboxのルート距離+実経過時間)。
/// バックエンドがGPSログから実測値を返せるようになったら差し替える想定。
/// 将来ストリーク(連続日数)や実績バッジを足すなら、この画面の統計エリアに追加していく
class TripSummaryScreen extends StatefulWidget {
  const TripSummaryScreen({
    super.key,
    required this.destinationName,
    required this.isRoundTrip,
    this.distanceM,
    this.duration,
    this.averageSpeedKmh,
    this.isArrival = false,
  });

  final String destinationName;
  final bool isRoundTrip;
  final bool isArrival;

  // 往路または往復の実走距離(メートル)。取得できなければnull
  final double? distanceM;

  // 案内開始〜終了の実経過時間(滞在時間も含む)。取得できなければnull
  final Duration? duration;

  // 距離÷経過時間から算出した平均速度(km/h)。distance/durationが揃わなければnull
  final double? averageSpeedKmh;

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // チェックマークの丸: ポンと弾むように出す
  late final Animation<double> _circleScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
  );

  // 丸の外側に広がって消えていく波紋
  late final Animation<double> _ringScale = Tween<double>(
    begin: 0.7,
    end: 1.6,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  late final Animation<double> _ringFade = Tween<double>(
    begin: 0.8,
    end: 0.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  // チェックのアイコン: 少し遅れてフワッと出す
  late final Animation<double> _checkFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 0.85, curve: Curves.easeIn),
  );

  // テキスト・統計・完了ボタン: 下からフワッとスライドイン
  late final Animation<double> _contentFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
  );
  late final Animation<Offset> _contentSlide = Tween<Offset>(
    begin: const Offset(0, 0.25),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
    ),
  );

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 距離(メートル)を「X.Xkm」の形式にする。未計測なら「--」
  String _distanceText() {
    final meters = widget.distanceM;
    if (meters == null) return '--';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  // 所要時間を「○時間○分」または「○分」にする。未計測なら「--」
  String _durationText() {
    final duration = widget.duration;
    if (duration == null) return '--';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return '$minutes分';
    return '$hours時間$minutes分';
  }

  // 平均速度(km/h)を小数1桁で出す。未計測なら「--」
  String _speedText() {
    final speed = widget.averageSpeedKmh;
    if (speed == null) return '--';
    return speed.toStringAsFixed(1);
  }

  // 「完了」を押したとき: RideFlowのスタックを先頭(HomeTabView)まで
  // 全部popして戻す。案内モード中の中途半端なRouteConfirmScreenを
  // 経由させずに一発で初期状態へ復帰させる
  void _finish() {
    HapticFeedback.lightImpact();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    // 画面下部の共通ナビゲーションバー(HOME・HISTORY・SETTINGS)が
    // 浮かんでいるため、完了ボタンが隠れないようにその分の高さを余白として確保する
    final bottomClearance =
        AppBottomNavigation.barHeightFor(context) + AppSpacing.md;

    return PopScope(
      // 端末の戻る操作では閉じさせず、必ず「完了」ボタンから戻す
      // (途中の状態のままRideFlowに戻ると表示が中途半端になるため)
      canPop: false,
      child: Scaffold(
        // 通常の背景(bgCool)ではなく、達成感を出すためあえて真っ白にする
        backgroundColor: AppColors.surface,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        0,
                        AppSpacing.xxl,
                        bottomClearance,
                      ),
                      child: Column(
                        children: [
                          const Spacer(flex: 3),
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                FadeTransition(
                                  opacity: _ringFade,
                                  child: ScaleTransition(
                                    scale: _ringScale,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                ScaleTransition(
                                  scale: _circleScale,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary,
                                    ),
                                    child: FadeTransition(
                                      opacity: _checkFade,
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 64,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          FadeTransition(
                            opacity: _contentFade,
                            child: SlideTransition(
                              position: _contentSlide,
                              child: Column(
                                children: [
                                  const Text(
                                    'お疲れさまでした!',
                                    style: AppTypography.pageTitle,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    widget.isArrival
                                        ? '目的地に到着しました'
                                        : (widget.isRoundTrip
                                            ? '${widget.destinationName}への往復ライドが完了しました'
                                            : '${widget.destinationName}へのライドが完了しました'),
                                    style: AppTypography.pageSubtitle,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpacing.xxxl),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _StatTile(
                                        icon: Icons.directions_bike_rounded,
                                        label: '距離',
                                        value: _distanceText(),
                                      ),
                                      _StatTile(
                                        icon: Icons.schedule_rounded,
                                        label: '時間',
                                        value: _durationText(),
                                      ),
                                      _StatTile(
                                        icon: Icons.speed_rounded,
                                        label: '平均速度',
                                        value: _speedText(),
                                        unit: 'km/h',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(flex: 4),
                          FadeTransition(
                            opacity: _contentFade,
                            child: SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                label: '完了',
                                onPressed: _finish,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// 統計1件分(アイコン+数値+ラベル)
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.accentBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text.rich(
          TextSpan(
            text: value,
            style: AppTypography.stat.copyWith(
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
            children:
                unit == null
                    ? null
                    : [TextSpan(text: ' $unit', style: AppTypography.label)],
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.label),
      ],
    );
  }
}
