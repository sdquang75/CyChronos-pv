import 'package:flutter/material.dart';

// Header for the Home tab (title/logo + greeting headline + subtitle).
class HomeHeroHeader extends StatelessWidget {
  const HomeHeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
