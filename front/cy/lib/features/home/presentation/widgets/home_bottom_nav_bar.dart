import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app_icons.dart';

// Floating frosted-glass pill bottom nav (Explore/Ride/Stats/Settings). The
// active-tab indicator morphs (slides + bumps in scale) between tabs on tap,
// and can also be dragged directly.
class HomeBottomNavBar extends StatefulWidget {
  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<HomeBottomNavBar> createState() => _HomeBottomNavBarState();
}

class _HomeBottomNavBarState extends State<HomeBottomNavBar>
    with SingleTickerProviderStateMixin {
  static const _tabCount = 4;
  static const _iconTabs = [
    (label: 'Explore', svg: AppIcons.exploreTab),
    (label: 'Ride', svg: AppIcons.rideTab),
    (label: 'Stats', svg: AppIcons.statsTab),
    (label: 'Settings', svg: AppIcons.settingsTab),
  ];

  late final AnimationController _controller;
  double _from = 0;
  double _to = 0;
  // Non-null while the user is actively dragging the indicator; overrides
  // the animated position with a 1:1 finger-follow value.
  double? _dragPosition;

  @override
  void initState() {
    super.initState();
    _from = widget.currentIndex.toDouble();
    _to = widget.currentIndex.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..value = 1;
  }

  @override
  void didUpdateWidget(covariant HomeBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragPosition == null &&
        oldWidget.currentIndex != widget.currentIndex) {
      _animateTo(widget.currentIndex.toDouble());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _from = _indicatorPosition;
    _to = target;
    _controller
      ..value = 0
      ..forward();
  }

  // Slight overshoot before settling reads as a "liquid" morph rather than a
  // linear slide.
  double get _indicatorPosition {
    if (_dragPosition != null) return _dragPosition!;
    final t = Curves.easeOutBack.transform(_controller.value);
    return _from + (_to - _from) * t;
  }

  // Bumps up mid-transition and settles back to 1.0 — the "scale nhẹ rồi ổn
  // định" bump the pill background gets while it moves.
  double get _bumpScale {
    if (_dragPosition != null) return 1.04;
    final t = _controller.value.clamp(0.0, 1.0);
    return 1 + 0.12 * math.sin(math.pi * t);
  }

  void _handleDragUpdate(DragUpdateDetails details, double tabWidth) {
    final fraction = (details.localPosition.dx / tabWidth).clamp(
      0.0,
      (_tabCount - 1).toDouble(),
    );
    setState(() => _dragPosition = fraction);
    final nearest = fraction.round();
    if (nearest != widget.currentIndex) {
      widget.onTap(nearest);
    }
  }

  void _handleDragEnd() {
    final settled =
        (_dragPosition ?? widget.currentIndex.toDouble()).round().toDouble();
    setState(() => _dragPosition = null);
    _animateTo(settled);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 35, right: 35, top: 15, bottom: 5),
      child: _buildPill(),
    );
  }

  Widget _buildPill() {
    // The frosted glass background (Positioned.fill) and the interactive
    // content (indicator + tab Row) are painted as SIBLINGS, not
    // parent/child. If the indicator lived inside the background's
    // ClipRRect(56), the pill's big capsule curve would slice into the
    // indicator's own smaller rounded corners at the first/last tab,
    // leaving one edge looking squared off. Keeping the indicator outside
    // that clip lets it render its own rounding cleanly, and Clip.none
    // lets it overshoot the tab's tight bounds for visible "bo dư" margin.
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(48),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(48),
                ),
              ),
            ),
          ),
        ),
        Padding(
          // Generous padding: the outer margin between the tab content and
          // the pill's true edge, giving the indicator room to overshoot
          // without ever nearing the capsule's curved ends.
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / _tabCount;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate:
                    (details) => _handleDragUpdate(details, tabWidth),
                onHorizontalDragEnd: (_) => _handleDragEnd(),
                onHorizontalDragCancel: _handleDragEnd,
                // No fixed height here: the Stack sizes itself to the tab
                // Row's natural (intrinsic) height, so larger system font
                // scales grow the pill instead of overflowing it.
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return Positioned(
                          left: _indicatorPosition * tabWidth + 2,
                          top: -6,
                          bottom: -6,
                          width: tabWidth - 4,
                          child: Transform.scale(
                            scale: _bumpScale,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF687966,
                                ).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Row(
                      children: List.generate(
                        _tabCount,
                        (index) => SizedBox(
                          width: tabWidth,
                          child: _buildTabItem(index),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabItem(int index) {
    final isSelected = widget.currentIndex == index;
    final color =
        isSelected ? const Color(0xFF4F604E) : const Color(0xFF5F5E5A);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.string(
            _iconTabs[index].svg,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(height: 4),
          Text(
            _iconTabs[index].label,
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
