import 'package:flutter/material.dart';

// アプリ全体の共通カラーパレット。CyChronosの現行デザインは紫系の
// ブランドカラー(#19005C)で統一されている。widgetから直接hexリテラルを
// 書く代わりにこのファイルのトークンを参照することで、配色を変えるときに
// このファイルだけ直せば済むようにする。
// (値は既存画面で最も使われているhexをそのまま集約したもの。見た目は変えていない)
class AppColors {
  AppColors._();

  // --- Brand purple(見出し・強調・アクション・ナビゲーション) ---
  static const primary = Color(0xFF19005C);
  static const primaryMuted = Color(0xFF6049C5);
  static const seed = Color(0xFF6750A4); // ThemeData.colorScheme.fromSeedの種
  static const glow = Color(0xFF2E0094); // ボタン等のシャドウ/グロー用
  static const snackbarBg = Color(0xFF2A0088);
  static const accentBg = Color(0xFFF1EBFF); // 選択中チップ・アクセント背景
  static const gradientStart = Color(0xFFE6DEFF); // ログイン画面の背景グラデーション

  // --- Neutral text ---
  static const textPrimary = Color(0xFF191C1F);
  static const textSecondary = Color(0xFF484553);

  // --- Surfaces / borders ---
  static const bgCool = Color(0xFFF8F9FE);
  static const surface = Colors.white; // カードなどの前面サーフェス
  static const border = Color(0xFFC9C4D5);

  // --- Semantic ---
  static const danger = Color(0xFFD93A2A); // 案内終了ボタン等
  static const error = Color(0xFFBA1A1A);
  static const warningBg = Color(0xFFFFF3E0); // ルート取得失敗時などの注意バナー
  static const starGold = Color(0xFFFFB300); // 評価の星

  // --- AppScreenFrame(PCブラウザ等の大画面プレビュー用) ---
  static const frameBackground = Color(0xFF191C1F);
}
