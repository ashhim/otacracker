import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color background = Color(0xFF020402);
  static const Color backgroundAlt = Color(0xFF071008);
  static const Color panel = Color(0xFF08140A);
  static const Color panelAlt = Color(0xFF0D1D11);
  static const Color panelRaised = Color(0xFF122816);
  static const Color neonBlue = Color(0xFF2BFF7A);
  static const Color neonGreen = Color(0xFF8DFFB0);
  static const Color neonAmber = Color(0xFFB7FF52);
  static const Color neonRed = Color(0xFFFF6E7F);
  static const Color textPrimary = Color(0xFFE8FFF0);
  static const Color textSecondary = Color(0xFF8EB89A);
  static const Color border = Color(0xFF1E4926);
  static const Color borderStrong = Color(0xFF46D86E);

  static ThemeData buildTheme() {
    const baseText = TextTheme(
      displaySmall: TextStyle(
        fontFamily: 'monospace',
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'monospace',
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
      titleLarge: TextStyle(
        fontFamily: 'monospace',
        fontWeight: FontWeight.w600,
        letterSpacing: 0.7,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'monospace',
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
      seedColor: neonGreen,
      brightness: Brightness.dark,
      primary: neonGreen,
      secondary: neonBlue,
      tertiary: neonAmber,
      surface: panel,
      error: neonRed,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
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
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: border),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: backgroundAlt,
        indicatorColor: Color(0x2646D86E),
        selectedIconTheme: IconThemeData(color: neonGreen),
        selectedLabelTextStyle: TextStyle(color: neonGreen, fontFamily: 'monospace'),
        unselectedIconTheme: IconThemeData(color: textSecondary),
        unselectedLabelTextStyle: TextStyle(color: textSecondary, fontFamily: 'monospace'),
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
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary),
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
          borderSide: const BorderSide(color: borderStrong),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonGreen,
          foregroundColor: background,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neonGreen,
          side: const BorderSide(color: borderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonGreen,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: neonGreen,
        linearTrackColor: panelAlt,
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
    );
  }
}
