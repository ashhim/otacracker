import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color background = Color(0xFF060A12);
  static const Color backgroundAlt = Color(0xFF0E1422);
  static const Color panel = Color(0xFF111A2E);
  static const Color panelAlt = Color(0xFF15233B);
  static const Color neonBlue = Color(0xFF3BE6FF);
  static const Color neonGreen = Color(0xFF67FF94);
  static const Color neonAmber = Color(0xFFFFC857);
  static const Color neonRed = Color(0xFFFF5370);
  static const Color textPrimary = Color(0xFFEAF8FF);
  static const Color textSecondary = Color(0xFF9CB1C9);
  static const Color border = Color(0xFF20324D);

  static ThemeData buildTheme() {
    const baseText = TextTheme(
      displaySmall: TextStyle(
        fontFamily: 'sans-serif-condensed',
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'sans-serif-condensed',
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
      titleLarge: TextStyle(
        fontFamily: 'sans-serif-condensed',
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'sans-serif',
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
      ),
      bodySmall: TextStyle(
        fontFamily: 'monospace',
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontFamily: 'monospace',
        fontWeight: FontWeight.w500,
        letterSpacing: 0.8,
      ),
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: neonBlue,
      brightness: Brightness.dark,
      primary: neonBlue,
      secondary: neonGreen,
      tertiary: neonAmber,
      surface: panel,
      error: neonRed,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
      textTheme: baseText.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: panel,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: backgroundAlt,
        indicatorColor: Color(0x223BE6FF),
        selectedIconTheme: IconThemeData(color: neonBlue),
        selectedLabelTextStyle: TextStyle(color: neonBlue),
        unselectedIconTheme: IconThemeData(color: textSecondary),
        unselectedLabelTextStyle: TextStyle(color: textSecondary),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: backgroundAlt,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: panelAlt,
        contentTextStyle: baseText.bodyMedium?.copyWith(color: textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: neonBlue),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonBlue,
          foregroundColor: background,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
    );
  }
}
