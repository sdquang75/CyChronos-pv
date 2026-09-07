import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// ログイン画面・スプラッシュ画面で共通の「オーロラ」背景(4隅から淡い紫の
/// radial gradientを重ねたもの)。2画面で全く同じ実装が重複していたので
/// 1つに集約する。
class AppAuroraBackground extends StatelessWidget {
  const AppAuroraBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.414,
                colors: [AppColors.gradientStart, const Color(0x00E6DEFF)],
                stops: const [0.0, 0.5],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.414,
                colors: [Color(0xFFFCF6FF), Color(0x00FCF6FF)],
                stops: [0.0, 0.5],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomRight,
                radius: 1.414,
                colors: [Color(0xFFE8DEFF), Color(0x00E8DEFF)],
                stops: [0.0, 0.5],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomLeft,
                radius: 1.414,
                colors: [AppColors.bgCool, const Color(0x00F8F9FE)],
                stops: const [0.0, 0.5],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
