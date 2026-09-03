import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// pushで開く画面(一覧・詳細・ルート確認・お問い合わせ等)で共通して使う
/// ヘッダー: 丸い戻るボタン + 太字タイトル + 下端の薄い区切り線。
/// タブのルート画面(HOME/HISTORY/SETTINGS)は代わりにロゴを直接表示するので
/// このウィジェットは使わない(戻るボタンが不要なため)。
/// fea/reformのAppTopBarと同じ構成をnative-ux-polishの配色に合わせて移植。
/// 上端のセーフエリアは自前で確保するので、Columnの子として置くだけでも、
/// (RouteConfirmScreenのように)Scaffold.appBarにPreferredSizeで包んで
/// 渡す使い方でも正しく表示される。preferredSizeが必要な場合は
/// [AppTopBar.heightFor] を使う(内部SafeAreaと同じ高さになる)
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.action,
  });

  final String title;

  /// 戻る操作のカスタム処理。省略時は素のNavigatorをpopする
  /// (RideFlow等の入れ子Navigatorでも正しく動く)
  final VoidCallback? onBack;

  /// 右端に表示する追加アクション(例: 削除ボタンなど)
  final Widget? action;

  /// コンテンツ自体の高さ(上端セーフエリアは含まない)
  static const double _contentHeight = 80;

  /// Scaffold.appBarに渡すときのpreferredSize用。実機の上端インセットを
  /// 含めた高さを返す(このウィジェット自身のSafeAreaと一致させる)
  static double heightFor(BuildContext context) =>
      _contentHeight + MediaQuery.of(context).padding.top;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.border.withValues(alpha: 0.3),
            ),
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
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
            ),
            if (action != null) ...[
              const SizedBox(width: AppSpacing.sm),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
