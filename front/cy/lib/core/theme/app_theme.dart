import 'package:flutter/material.dart';

class AppTheme {
  static const _snackBarTheme = SnackBarThemeData(
    backgroundColor: Color(0xFF2A0088),
    contentTextStyle: TextStyle(
      color: Colors.white,
      fontFamily: 'HankenGrotesk',
      fontFamilyFallback: ['NotoSansJP'],
    ),
    actionTextColor: Colors.white,
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
    snackBarTheme: _snackBarTheme,
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.dark,
    ),
    snackBarTheme: _snackBarTheme,
  );
}
