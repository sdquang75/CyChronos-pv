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
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
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
              child: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: AppColors.greenPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
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
