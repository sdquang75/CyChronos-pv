import 'package:flutter/material.dart';

// Central color palette for CyChronos. A single green brand family runs
// through the whole app (headings, emphasis, actions, navigation) instead of
// the old two-family (terracotta + green) split, kept deliberately small —
// a handful of tokens, muted/desaturated tones, no unrelated accent hues.
// Widgets reference these tokens instead of inlining hex literals, so
// retoning the app means editing this file alone.
class AppColors {
  AppColors._();

  // --- Brand green (headings, emphasis, actions, navigation) ---
  static const greenDeep = Color(0xFF243B2B);
  static const greenPrimary = Color(0xFF3F6148);
  static const greenAccent = Color(0xFF6E8F72);
  static const greenIndicator = Color(0xFF7C9481);
  static const greenChipBg = Color(0xFFE6EEE4);
  static const greenChipBgLight = Color(0xFFDCE7DD);
  static const greenBorder = Color(0xFFCCDACB);
  static const greenGradient = Color(0xFFD8E8D5);
  static const greenHaze = Color(0xFFEAF2E7);
  static const greenShadow = Color(0xFF16221A);

  // --- Neutral text ---
  static const textPrimary = Color(0xFF1B1C1C);
  static const textSecondary = Color(0xFF48524C);
  static const textMuted = Color(0xFF6B756F);

  // --- Surfaces / borders ---
  static const bgCool = Color(0xFFF8F9FE);
  static const bgWarm = Color(0xFFFDFCF8);
  static const borderLight = Color(0xFFD1D5D0);
  static const borderMedium = Color(0xFFC4C8C0);
  static const dividerLight = Color(0xFFE4E2E1);
  static const surfaceHover = Color(0xFFF6F3F2);
  static const frameBackground = Color(0xFF191C1F);

  // --- Semantic ---
  static const danger = Color(0xFFEA4335);
}
