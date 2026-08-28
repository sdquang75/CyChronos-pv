import 'package:flutter/material.dart';

import 'app_colors.dart';

// アプリ全体で使うテキストスタイルの定義。画面ごとに似たようなTextStyleを
// 個別に書く代わりに、役割ベースの名前(pageTitle, cardTitle...)で
// 呼び出せるようにする。フォントファミリー(HankenGrotesk / Inter /
// JetBrainsMono)と役割ごとのサイズ/太さは、既存画面で実際に使われていた
// 組み合わせをそのまま踏襲している(見た目は変えていない)。
class AppTypography {
  AppTypography._();

  static const _hanken = 'HankenGrotesk';
  static const _jaFallback = ['NotoSansJP'];
  static const _inter = 'Inter';
  static const _mono = 'JetBrainsMono';

  /// ページの大見出し(例:「おすすめスポット」「設定」「アクティビティ履歴」)
  static const pageTitle = TextStyle(
    fontFamily: _hanken,
    fontFamilyFallback: _jaFallback,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    color: AppColors.primary,
    height: 1.25,
  );

  /// ページ見出しの下に添える説明文
  static const pageSubtitle = TextStyle(
    fontFamily: _inter,
    fontFamilyFallback: _jaFallback,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  /// カードのタイトル(スポット名、トリップ名など)
  static const cardTitle = TextStyle(
    fontFamily: _hanken,
    fontFamilyFallback: _jaFallback,
    fontWeight: FontWeight.w700,
    fontSize: 17,
    color: AppColors.primary,
    height: 1.25,
  );

  /// セクションの小見出し(例:「DURATION」「INTEREST」「STATISTICS」)。
  /// 英大文字ラベル用であることが多い
  static const sectionLabel = TextStyle(
    fontFamily: _mono,
    fontWeight: FontWeight.w500,
    fontSize: 13,
    letterSpacing: 0.7,
    color: AppColors.textSecondary,
  );

  /// 本文・値のテキスト(住所、説明文など)
  static const body = TextStyle(
    fontFamily: _inter,
    fontFamilyFallback: _jaFallback,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// ラベル(項目名。「距離」「所要時間」など)
  static const label = TextStyle(
    fontFamily: _hanken,
    fontFamilyFallback: _jaFallback,
    fontWeight: FontWeight.w500,
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  /// 数値バッジ・統計値(等幅フォントで揃える)
  static const stat = TextStyle(
    fontFamily: _mono,
    fontWeight: FontWeight.w700,
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  /// ボタンのラベル
  static const button = TextStyle(
    fontFamily: _hanken,
    fontFamilyFallback: _jaFallback,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: Colors.white,
  );
}
