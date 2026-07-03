import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app_icons.dart';

// Custom frosted-glass bottom navigation bar (Home/Route/History/Profile).
class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static final _tabs = [
    {'label': 'HOME', 'svg': AppIcons.homeTab},
    {'label': 'ROUTE', 'svg': AppIcons.routeTab},
    {'label': 'HISTORY', 'svg': AppIcons.historyTab},
    {'label': 'PROFILE', 'svg': AppIcons.profileTab},
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FE).withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: const Color(0xFFC9C4D5).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.only(top: 12, bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (index) {
              final tab = _tabs[index];
              final isSelected = currentIndex == index;
              final color =
                  isSelected
                      ? const Color(0xFF19005C)
                      : const Color(0xFF484553);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(index),
                child: SizedBox(
                  width: 70,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 24,
                        width: 28,
                        child: SvgPicture.string(
                          tab['svg']!,
                          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab['label']!,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 11,
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
    );
  }
}
