import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const background = Color(0xFF090B10);
  static const panel = Color(0xCC11151C);
  static const panelStrong = Color(0xFF171C25);
  static const accent = Color(0xFFF2B95C);
  static const accentMuted = Color(0xFF9E7A3D);
  static const error = Color(0xFFEC6F66);
  static const success = Color(0xFF4DD08A);
  static const textPrimary = Color(0xFFF7F2E9);
  static const textMuted = Color(0xFFB8B4AA);

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme =
        GoogleFonts.courierPrimeTextTheme(base.textTheme).copyWith(
      displaySmall: GoogleFonts.cormorantGaramond(
        color: textPrimary,
        fontSize: 42,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
      titleLarge: GoogleFonts.courierPrime(
        color: textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
      titleMedium: GoogleFonts.courierPrime(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: GoogleFonts.courierPrime(
        color: textPrimary,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.courierPrime(
        color: textPrimary,
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.courierPrime(
        color: textMuted,
        fontSize: 12,
        height: 1.35,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentMuted,
        surface: panel,
        error: error,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textPrimary,
        titleTextStyle: textTheme.titleLarge,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: panelStrong,
        selectedColor: accent,
        disabledColor: panelStrong.withOpacity(0.6),
        labelStyle: textTheme.bodySmall,
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(color: Colors.black),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: Color(0x553B4250),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: panelStrong,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
