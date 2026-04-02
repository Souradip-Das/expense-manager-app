// lib/services/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ─── Brand Colors ──────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF7B4FD4); // vibrant purple
  static const Color primaryLight   = Color(0xFF9B6FE8); // light purple
  static const Color primaryDark    = Color(0xFF5A35A8); // dark purple
  static const Color gradientStart  = Color(0xFF7B4FD4); // purple
  static const Color gradientEnd    = Color(0xFF4A8FE8); // blue

  // ─── Background ────────────────────────────────────────────────────────────
  static const Color bgColor        = Color(0xFF0D0D0F);
  static const Color cardBg         = Color(0xFF1C1C1F);
  static const Color cardBgAlt      = Color(0xFF242428);
  static const Color sectionBg      = Color(0xFF141416);

  // ─── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary    = Colors.white;
  static const Color textSecondary  = Color(0xFFAAAAAF);
  static const Color textMuted      = Color(0xFF606068);

  // ─── Accents ───────────────────────────────────────────────────────────────
  static const Color accentGreen    = Color(0xFF2ECC71);
  static const Color accentRed      = Color(0xFFE74C3C);
  static const Color accentAmber    = Color(0xFFF39C12);
  static const Color accentBlue     = Color(0xFF4A8FE8);

  // ─── Border ────────────────────────────────────────────────────────────────
  static const Color borderColor    = Color(0xFF2A2A30);

  // ─── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF5A35A8), Color(0xFF3A6FCC), Color(0xFF2A8FD8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF7B4FD4), Color(0xFF4A8FE8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFC0392B), Color(0xFFE74C3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Theme ─────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgColor,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: primaryLight,
          surface: cardBg,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: cardBg,
          margin: EdgeInsets.zero,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: textPrimary),
          bodySmall: TextStyle(color: textSecondary),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF242428),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: Color(0xFF9B6FE8)),
          hintStyle: const TextStyle(color: Color(0xFF555560)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}
