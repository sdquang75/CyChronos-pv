import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app_icons.dart';

// Floating frosted-glass pill bottom navigation bar (Ride/Explore/Stats/Settings).
class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static final _tabs = [
    (label: 'Ride', svg: AppIcons.rideTab),
    (label: 'Explore', svg: AppIcons.exploreTab),
    (label: 'Stats', svg: AppIcons.statsTab),
    (label: 'Settings', svg: AppIcons.settingsTab),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 35, right: 35, top: 15, bottom: 5),
      child: ClipRRect(
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final tab = _tabs[index];
                final isSelected = currentIndex == index;
                final color =
                    isSelected
                        ? const Color(0xFF19005C)
                        : const Color(0xFF484553);

                // Flexible width per tab (Figma: flex-[1_0_0]) so the pill
                // fits on narrow phones instead of overflowing a fixed width.
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(index),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.string(
                          tab.svg,
                          width: 24,
                          height: 22,
                          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
