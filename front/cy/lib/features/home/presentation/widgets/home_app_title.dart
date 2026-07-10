import 'package:flutter/material.dart';
import 'package:cy/core/theme/app_colors.dart';

// Top-of-screen app title ("CyChronos") shown above the Home tab content.
class HomeAppTitle extends StatelessWidget {
  const HomeAppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'CyChronos',
      style: TextStyle(
        fontFamily: 'HankenGrotesk',
        fontFamilyFallback: ['NotoSansJP'],
        fontWeight: FontWeight.w600,
        fontSize: 36,
        letterSpacing: -0.9,
        color: AppColors.greenIcon,
        height: 1.22,
      ),
    );
  }
}
