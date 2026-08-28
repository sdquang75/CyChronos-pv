import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// アプリ全体で使う共通カード(白背景 + 薄い枠線 + 淡いシャドウ)。
/// 目的地カード・トリップカード・設定カード・空状態/エラー状態の表示など、
/// 画面ごとに同じdecorationを個別に書いていたのをこれ1つに集約する。
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md + 2),
    this.margin,
    this.borderRadius = AppSpacing.radiusCard,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.glow.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
