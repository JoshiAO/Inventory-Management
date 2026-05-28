import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeType { inventory, kenea }

class AppTheme {
  // Inventory (Original Green)
  static const Color invPrimary = Color(0xFF2D6A4F);
  static const Color invSecondary = Color(0xFF40916C);

  // KENEA (Blue Logo Based)
  static const Color keneaPrimary = Color(0xFF1E88E5);
  static const Color keneaSecondary = Color(0xFF64B5F6);

  static const Color warning = Color(0xFFF77F00);
  static const Color success = Color(0xFF52B788);
  static const Color error = Color(0xFFD00000);
  static const Color surface = Color(0xFFF8F9FA);

  static ThemeData getTheme(AppThemeType type) {
    Color primary = type == AppThemeType.kenea ? keneaPrimary : invPrimary;
    Color secondary = type == AppThemeType.kenea ? keneaSecondary : invSecondary;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}
