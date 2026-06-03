import 'package:flutter/material.dart';

class PulseTheme {
  // â”€â”€ Core Palette â”€â”€
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color background = Color(0xFF050B1A);
  static const Color surface = Color(0xFF0D1730);
  static const Color surfaceElevated = Color(0xFF101B37);
  static const Color textPrimary = Color(0xFFF8FBFF);
  static const Color textSecondary = Color(0xFFB9C5E4);
  static const Color textTertiary = Color(0xFF7180A6);
  static const Color border = Color(0xFF263455);
  static const Color borderLight = Color(0xFF1A2746);

  // â”€â”€ Category Palette â”€â”€
  static const Color magazineContent = Color(0xFF10B981);
  static const Color courseContent = Color(0xFF8B5CF6);
  static const Color eventContent = Color(0xFFF59E0B);
  static const Color newsContent = Color(0xFFEF4444);

  // â”€â”€ Gradient Definitions â”€â”€
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: [Color(0xFF101B37), Color(0xFF1A2746), Color(0xFF101B37)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient avatarRingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF8B5CF6), Color(0xFFEC4899)],
  );

  // â”€â”€ Shadows â”€â”€
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.28),
      blurRadius: 22,
      offset: const Offset(0, 12),
      spreadRadius: -12,
    ),
    BoxShadow(
      color: primary.withValues(alpha: 0.10),
      blurRadius: 22,
      offset: const Offset(0, 8),
      spreadRadius: -18,
    ),
  ];

  static List<BoxShadow> get softGlowShadow => [
    BoxShadow(
      color: primaryLight.withValues(alpha: 0.16),
      blurRadius: 26,
      offset: const Offset(0, 12),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.32),
      blurRadius: 26,
      offset: const Offset(0, 14),
      spreadRadius: -14,
    ),
  ];

  static List<BoxShadow> coloredShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  // â”€â”€ Durations & Curves â”€â”€
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Curve animCurve = Curves.easeOutCubic;

  // â”€â”€ Theme Data â”€â”€
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        secondary: Color(0xFF8B5CF6),
        surface: surface,
        onSurface: textPrimary,
        error: Color(0xFFEF4444),
      ),
      fontFamily: 'Avenir',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          height: 1.15,
        ),
        displayMedium: TextStyle(
          color: textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.25,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14, height: 1.45),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
