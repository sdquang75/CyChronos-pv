import 'package:flutter/material.dart';

// Header for the Home tab (title/logo + greeting headline + subtitle).
class HomeHeroHeader extends StatelessWidget {
  const HomeHeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CyChronos',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontFamilyFallback: ['NotoSansJP'],
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF19005C),
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'RIDE PLANNER',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF19005C).withValues(alpha: 0.6),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          '今日はどのくらい走る？',
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w700,
            fontSize: 28,
            color: Color(0xFF19005C),
            height: 1.29,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '目標時間を設定して、最適なルートを見つけましょう。',
          style: TextStyle(
            fontFamily: 'Inter',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Color(0xFF484553),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
