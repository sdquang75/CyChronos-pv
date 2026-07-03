import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app_icons.dart';

// Floating frosted-glass pill bottom nav (Ride/Explore/Stats/Profile) plus a
// separate circular search bubble. The active-tab indicator morphs (slides +
// bumps in scale) between tabs on tap, and can also be dragged directly.
class HomeBottomNavBar extends StatefulWidget {
  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onSearchTap,
    this.avatarUrl,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onSearchTap;
  final String? avatarUrl;

  @override
  State<HomeBottomNavBar> createState() => _HomeBottomNavBarState();
}

class _HomeBottomNavBarState extends State<HomeBottomNavBar>
    with SingleTickerProviderStateMixin {
  static const _tabCount = 4;
  static const _iconTabs = [
    (label: 'Ride', svg: AppIcons.rideTab),
    (label: 'Explore', svg: AppIcons.exploreTab),
    (label: 'Stats', svg: AppIcons.statsTab),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _buildPill()),
          const SizedBox(width: 12),
          _buildSearchBubble(),
        ],
      ),
    );
  }

  Widget _buildPill() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(56),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FE).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(56),
            border: Border.all(
              color: const Color(0xFFC9C4D5).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
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
                // scales grow the pill instead of overflowing it. The
                // indicator uses top+bottom (not a hardcoded height) to
                // always match that same height exactly.
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return Positioned(
                          left: _indicatorPosition * tabWidth + 4,
                          top: 0,
                          bottom: 0,
                          width: tabWidth - 8,
                          child: Transform.scale(
                            scale: _bumpScale,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF19005C,
                                ).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
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
      ),
    );
  }

  Widget _buildTabItem(int index) {
    final isSelected = widget.currentIndex == index;
    final color =
        isSelected ? const Color(0xFF19005C) : const Color(0xFF484553);
    final isAvatar = index == _tabCount - 1;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAvatar)
            _AvatarIcon(url: widget.avatarUrl, color: color)
          else
            SvgPicture.string(
              _iconTabs[index].svg,
              width: 20,
              height: 18,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          const SizedBox(height: 3),
          Text(
            isAvatar ? 'Profile' : _iconTabs[index].label,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBubble() {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF8F9FE).withValues(alpha: 0.8),
            border: Border.all(
              color: const Color(0xFFC9C4D5).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onSearchTap,
              child: const Center(
                child: Icon(
                  Icons.search_rounded,
                  color: Color(0xFF19005C),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarIcon extends StatelessWidget {
  const _AvatarIcon({required this.url, required this.color});

  final String? url;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.2),
      ),
      child: ClipOval(
        child:
            url != null
                ? Image.network(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, _, _) =>
                          Icon(Icons.person_rounded, size: 13, color: color),
                )
                : Icon(Icons.person_rounded, size: 13, color: color),
      ),
    );
  }
}
