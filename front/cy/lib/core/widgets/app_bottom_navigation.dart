import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// 画面下部メニューバーのタブ種別
enum AppTab { home, history, settings }

/// 全画面共通の画面下部メニューバー。
/// おすすめスポット一覧画面の形式(左からHOME・HISTORY・SETTINGS)に統一する。
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

  /// いま表示している画面のタブ(ハイライト表示用)。
  /// おすすめ一覧や詳細のようにタブ本体ではない画面でもHOMEを渡してよい
  /// (遷移するかどうかは実際のルートで判定する)
  final AppTab current;

  const AppBottomNavigation({
    super.key,
    required this.current,
  });

  // すでに表示中のルートをもう一度タップしたときだけ遷移しない。
  // ハイライト(current)とは別に実ルートで判定する
  // (例: おすすめ一覧はHOMEをハイライトするが、ルートは/destinationなので
  //  HOMEタップで/homeへ移動できる必要がある)
  void _goTo(BuildContext context, String path) {
    final String location =
        GoRouterState.of(context).matchedLocation;
    if (location == path) return;
    HapticFeedback.selectionClick();
    context.go(path);
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
            color: const Color(0xFFF8F9FE).withValues(
              alpha: 0.8,
            ),
            border: Border(
              top: BorderSide(
                color: const Color(0xFFC9C4D5).withValues(
                  alpha: 0.3,
                ),
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
                  isSelected: current == AppTab.home,
                  onTap: () {
                    _goTo(context, '/home');
                  },
                ),
                _BottomNavItem(
                  label: 'HISTORY',
                  svgData: _kHistoryTabSvg,
                  isSelected: current == AppTab.history,
                  onTap: () {
                    _goTo(context, '/history');
                  },
                ),
                _BottomNavItem(
                  label: 'SETTINGS',
                  icon: Icons.settings_outlined,
                  isSelected: current == AppTab.settings,
                  onTap: () {
                    _goTo(context, '/settings');
                  },
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
        ? const Color(0xFF19005C)
        : const Color(0xFF484553);

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
