import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// 全画面共通の画面下部メニューバー。
/// おすすめスポット一覧画面の形式(左からHOME・HISTORY・SETTINGS)に統一する。
///
/// タブの切り替えはHomeScreen(IndexedStackシェル)のcurrentIndex/onTapで
/// 制御する「dumbな」コンポーネント。go_routerへは依存しない
/// (タブ切り替えはページ遷移ではなくIndexedStackのインデックス変更のため)
class AppBottomNavigation extends StatelessWidget {
  /// アイコン+ラベル部分の高さ(下端の余白は含まない)
  static const double _contentHeight = 68.92;

  /// 端末に下部セーフエリアが無い機種向けの最低限の余白
  /// (3ボタンナビ以前を想定した元々のデザイン値)
  static const double _minBottomInset = 20;

  /// メニューバーの実際の高さ。ジェスチャーナビゲーションバーやホームインジケーターの
  /// 実測の余白(MediaQuery.padding.bottom)に応じて可変にし、被らないようにする。
  /// 各画面で本文の下余白(Positionedのbottom等)にはこれを使う
  static double barHeightFor(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    return _contentHeight +
        (bottomInset > _minBottomInset ? bottomInset : _minBottomInset);
  }

  /// いま選択中のタブ(0: HOME, 1: HISTORY, 2: SETTINGS)
  final int currentIndex;

  /// タブがタップされたときに呼ばれる(既に選択中のタブを再タップした場合も含む。
  /// 何もしないかどうかは呼び出し側で判断する)
  final ValueChanged<int> onTap;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  void _handleTap(int index) {
    // 既に選択中のタブを再タップした場合も呼び出し側に通知する
    // (例: HOMEタブ再タップで目的地一覧/詳細を閉じてトップまで戻す用)
    HapticFeedback.selectionClick();
    onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCool.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: AppColors.border.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.only(top: 12),
          // 端末の実際の下部インセット(ジェスチャーナビゲーションバー/ホーム
          // インジケーター)がminimumより大きい場合はそちらを優先して被りを防ぐ
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            minimum: const EdgeInsets.only(bottom: _minBottomInset),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  label: 'HOME',
                  svgData: _kHomeTabSvg,
                  isSelected: currentIndex == 0,
                  onTap: () => _handleTap(0),
                ),
                _BottomNavItem(
                  label: 'HISTORY',
                  svgData: _kHistoryTabSvg,
                  isSelected: currentIndex == 1,
                  onTap: () => _handleTap(1),
                ),
                _BottomNavItem(
                  label: 'SETTINGS',
                  icon: Icons.settings_outlined,
                  isSelected: currentIndex == 2,
                  onTap: () => _handleTap(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final String? svgData;
  final IconData? icon;
  final bool isSelected;

  const _BottomNavItem({
    required this.label,
    required this.onTap,
    this.svgData,
    this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected
        ? AppColors.primary
        : AppColors.textSecondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 70,
        // 枠に収まらないときだけ自動で縮小し、はみ出しを防ぐ
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 24,
                child: icon != null
                    ? Icon(
                        icon,
                        color: color,
                        size: 25,
                      )
                    : SvgPicture.string(
                        svgData!,
                        colorFilter: ColorFilter.mode(
                          color,
                          BlendMode.srcIn,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 11,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _kHomeTabSvg = '''
<svg viewBox="0 0 24 24" fill="none"
    xmlns="http://www.w3.org/2000/svg">
  <path
    d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"/>
  <path
    d="M9 22V12h6v10"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"/>
</svg>
''';

const _kHistoryTabSvg = '''
<svg viewBox="0 0 24 24" fill="none"
    xmlns="http://www.w3.org/2000/svg">
  <circle
    cx="12"
    cy="12"
    r="10"
    stroke="currentColor"
    stroke-width="2"/>
  <path
    d="M12 6V12L16 14"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"/>
</svg>
''';
