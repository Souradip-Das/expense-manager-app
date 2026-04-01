// lib/services/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ─── Brand Colors ──────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF6A0DAD); // deep purple
  static const Color primaryLight   = Color(0xFF9B59B6); // lighter purple
  static const Color primaryDark    = Color(0xFF4A0080); // darker purple

  // ─── Background Colors ─────────────────────────────────────────────────────
  static const Color bgColor        = Color(0xFF0D0D0D); // main background
  static const Color cardBg         = Color(0xFF1A1A1A); // card background
  static const Color cardBgAlt      = Color(0xFF1F1F1F); // slightly lighter card
  static const Color sectionBg      = Color(0xFF141414); // section background

  // ─── Text Colors ───────────────────────────────────────────────────────────
  static const Color textPrimary    = Colors.white;
  static const Color textSecondary  = Color(0xFFB0B0B0);
  static const Color textMuted      = Color(0xFF6E6E6E);

  // ─── Accent Colors (for icons/badges only) ─────────────────────────────────
  static const Color accentGreen    = Color(0xFF27AE60);
  static const Color accentRed      = Color(0xFFE74C3C);
  static const Color accentAmber    = Color(0xFFF39C12);

  // ─── Border ────────────────────────────────────────────────────────────────
  static const Color borderColor    = Color(0xFF2A2A2A);
  static const Color accentBorder   = primary; // left border on cards

  // ─── Category left border accent width ────────────────────────────────────
  static const double categoryBorderWidth = 4.0;

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
          backgroundColor: primary,
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
          bodySmall:  TextStyle(color: textSecondary),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF242424),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: Color(0xFF9B59B6)),
          hintStyle:  const TextStyle(color: Color(0xFF555555)),
        ),
      );
}
