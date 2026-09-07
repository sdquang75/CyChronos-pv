import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// 各画面のコンテンツを共通の「スマホフレーム」で包む。
// 実機(幅450 x 高さ943以下)ではそのまま全画面表示し、
// それより広い/高いビューポート(PCブラウザでのプレビューなど)では
// 中央に固定サイズの角丸フレーム+影で表示することで、
// 画面ごとにバラバラだった枠サイズを統一する。
// 450x943はfea/reformのFigmaレスポンシブ設計と同じ値(390だとPro Max級の
// 大画面実機(論理幅428dp前後)まで誤ってPCプレビュー扱いになっていた)
class AppScreenFrame extends StatelessWidget {
  const AppScreenFrame({super.key, required this.child});

  final Widget child;

  static const double width = 450;
  static const double height = 943;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > width || size.height > height;

    if (!isLargeScreen) return child;

    return Scaffold(
      backgroundColor: AppColors.frameBackground,
      body: Center(
        child: Container(
          width: width,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
