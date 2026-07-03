import 'package:flutter/material.dart';

// Shared title/subtitle header used by the Route, History and Profile tabs.
class HomeTabHeader extends StatelessWidget {
  const HomeTabHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w700,
            fontSize: 28,
            color: Color(0xFF19005C),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF484553),
          ),
        ),
      ],
    );
  }
}
