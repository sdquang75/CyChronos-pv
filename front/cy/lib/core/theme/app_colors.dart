import 'package:flutter/material.dart';

// Central color palette for CyChronos. Two brand families run through the
// app: terracotta (headings/emphasis — auth screens, Route/History/Profile
// tabs) and green (primary actions/navigation — Home tab, Destination,
// Route Confirm, bottom nav). Widgets reference these tokens instead of
// inlining hex literals, so retoning the app means editing this file alone.
class AppColors {
  AppColors._();

  // --- Terracotta family (headings, emphasis, auth) ---
  static const terracottaDeep = Color(0xFF4A2416);
  static const terracottaAccent = Color(0xFF8A4B32);
  static const terracottaShadow = Color(0xFF6B3A22);
  static const terracottaGlow = Color(0xFFC97B4A);
  static const terracottaChipBg = Color(0xFFF5E6DA);
  static const terracottaBorder = Color(0xFFD9C3B3);
  static const terracottaHazeA = Color(0xFFF3E1D3);
  static const terracottaHazeB = Color(0xFFF6E4D6);
  static const terracottaHazeC = Color(0xFFFDF6EF);
  static const terracottaCardShadow = Color(0xFF3D2417);

  // --- Green family (CTA / navigation / actions) ---
  static const greenPrimary = Color(0xFF4A654E);
  static const greenIcon = Color(0xFF4F604E);
  static const greenIndicator = Color(0xFF687966);
  static const greenChipBg = Color(0xFFE7F0E4);
  static const greenChipBgLight = Color(0xFFDDE6DE);
  static const greenGradient = Color(0xFFD5E8D1);
  static const greenSocial = Color(0xFF8BA88E);

  // --- Neutral text ---
  static const textPrimary = Color(0xFF1B1C1C);
  static const textSecondary = Color(0xFF484553);
  static const textMuted = Color(0xFF5F5E5A);
  static const textSlate = Color(0xFF475569);
  static const textSlateMuted = Color(0xFF64748B);
  static const textSlateDark = Color(0xFF334155);
  static const textOliveMuted = Color(0xFF424842);

  // --- Surfaces / borders ---
  static const bgCool = Color(0xFFF8F9FE);
  static const bgWarm = Color(0xFFFDFCF8);
  static const borderLight = Color(0xFFD1D5D0);
  static const borderSubtle = Color(0xFFC2C8C0);
  static const borderMedium = Color(0xFFC4C8C0);
  static const dividerLight = Color(0xFFE4E2E1);
  static const surfaceHover = Color(0xFFF6F3F2);
  static const frameBackground = Color(0xFF191C1F);

  // --- Semantic ---
  static const danger = Color(0xFFEA4335);
}
