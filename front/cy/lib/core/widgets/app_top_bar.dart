import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cy/core/theme/app_colors.dart';

// Shared "Header - TopAppBar" from the Figma Confirm Route frame: back
// button + bold title with a bottom hairline. Reused by any screen that
// needs the same back-navigation header (Confirm Route, destination
// search, ...). Top padding matches HomeTabView's 20px inset above the
// "CyChronos" title so the back button sits level with it, clear of the
// safe-area edge/notch.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.fallbackRoute = '/home',
  });

  final String title;
  final VoidCallback? onBack;
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Material(
            // Filled circle instead of a bare icon, so the button reads as
            // tappable at a glance (iOS/Android both give back buttons a
            // clear hit-target affordance, not just a floating glyph).
            color: AppColors.greenChipBg,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap:
                  onBack ??
                  () {
                    // Prefer popping the nearest Navigator (e.g. the Explore
                    // tab's own nested flow) before falling back to the
                    // app-wide GoRouter stack.
                    final navigator = Navigator.of(context);
                    if (navigator.canPop()) {
                      navigator.pop();
                    } else if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(fallbackRoute);
                    }
                  },
              // 44x44 hit target (iOS HIG minimum / Android's comfortable
              // touch size) — the old 26x26 icon-only button was too small
              // to hit reliably.
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.greenPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'HankenGrotesk',
              fontFamilyFallback: ['NotoSansJP'],
              fontWeight: FontWeight.w700,
              fontSize: 22,
              letterSpacing: -0.55,
              color: AppColors.greenPrimary,
              height: 28 / 22,
            ),
          ),
        ],
      ),
    );
  }
}
