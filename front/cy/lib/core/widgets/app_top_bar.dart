import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// pushで開く画面(一覧・詳細・ルート確認・お問い合わせ等)で共通して使う
/// ヘッダー: 丸い戻るボタン + 太字タイトル + 下端の薄い区切り線。
/// タブのルート画面(HOME/HISTORY/SETTINGS)は代わりにロゴを直接表示するので
/// このウィジェットは使わない(戻るボタンが不要なため)。
/// fea/reformのAppTopBarと同じ構成をnative-ux-polishの配色に合わせて移植
class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key, required this.title, this.onBack});

  final String title;

  /// 戻る操作のカスタム処理。省略時は素のNavigatorをpopする
  /// (RideFlow等の入れ子Navigatorでも正しく動く)
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Material(
            // 丸い塗りつぶし背景にすることで、一目でタップ可能だとわかるようにする
            color: AppColors.accentBg,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              // 44x44のヒット領域(iOS/Androidの推奨最小タップサイズ)
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'HankenGrotesk',
              fontFamilyFallback: ['NotoSansJP'],
              fontWeight: FontWeight.w700,
              fontSize: 22,
              letterSpacing: -0.55,
              color: AppColors.primary,
              height: 28 / 22,
            ),
          ),
        ],
      ),
    );
  }
}
