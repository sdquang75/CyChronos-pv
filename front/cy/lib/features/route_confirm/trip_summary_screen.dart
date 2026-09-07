import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/tap_scale.dart';

/// 走行終了後に出す完了画面 (Apple Fitnessスタイルの達成感あふれる画面).
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

  late final Animation<double> _circleScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
  );

  late final Animation<double> _ringScale = Tween<double>(
    begin: 0.7,
    end: 1.6,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  late final Animation<double> _ringFade = Tween<double>(
    begin: 0.8,
    end: 0.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  late final Animation<double> _checkFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 0.85, curve: Curves.easeIn),
  );

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
    // 完了画面の達成感・余韻を邪魔しないよう、残っているトースト通知を即時消去する
    AppToast.clear();
    HapticFeedback.mediumImpact();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _distanceText() {
    final meters = widget.distanceM;
    if (meters == null) return '--';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  String _durationText() {
    final duration = widget.duration;
    if (duration == null) return '--';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return '$minutes分';
    return '$hours時間$minutes分';
  }

  String _speedText() {
    final speed = widget.averageSpeedKmh;
    if (speed == null) return '--';
    return speed.toStringAsFixed(1);
  }

  void _finish() {
    HapticFeedback.lightImpact();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final bottomClearance =
        AppBottomNavigation.barHeightFor(context) + AppSpacing.md;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
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
                        24,
                        0,
                        24,
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
                          const SizedBox(height: 28),
                          FadeTransition(
                            opacity: _contentFade,
                            child: SlideTransition(
                              position: _contentSlide,
                              child: Column(
                                children: [
                                  const Text(
                                    'お疲れさまでした!',
                                    style: TextStyle(
                                      fontFamily: 'HankenGrotesk',
                                      fontFamilyFallback: ['NotoSansJP'],
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: -0.6,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.isArrival
                                        ? '目的地に到着しました'
                                        : (widget.isRoundTrip
                                            ? '${widget.destinationName}への往復ライドが完了しました'
                                            : '${widget.destinationName}へのライドが完了しました'),
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontFamilyFallback: ['NotoSansJP'],
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 36),
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
                              child: TapScale(
                                onTap: _finish,
                                child: AppButton(
                                  label: '完了',
                                  height: 52,
                                  borderRadius: 18,
                                  onPressed: _finish,
                                ),
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

// Apple Fitnessスタイルの統計タイル
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
          decoration: BoxDecoration(
            color: AppColors.accentBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            text: value,
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
            children: unit == null
                ? null
                : [
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
