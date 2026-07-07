import 'package:flutter/material.dart';

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
        color: Color(0xFF4F604E),
        height: 1.22,
      ),
    );
  }
}
