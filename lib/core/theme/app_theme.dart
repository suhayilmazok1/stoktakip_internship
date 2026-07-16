import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Renk Paleti (Statik Marka Renkleri) ──
  static const Color scaffoldDark = Color(0xFF0A0E21);
  static const Color cardDarkColor = Color(0xFF1A1F36);
  static const Color surfaceDark = Color(0xFF151929);
  static const Color primaryBlue = Color(0xFF4C6FFF);
  static const Color primaryBlueLight = Color(0xFF6C8CFF);
  static const Color accentCyan = Color(0xFF00D9FF);
  static const Color accentPink = Color(0xFFE94560);
  static const Color errorRed = Color(0xFFFF6B6B);
  static const Color successGreen = Color(0xFF00E096);

  // Yordam Red (Açık mod için kurumsal renk)
  static const Color yordamRed = Color(0xFFDE1F3C);

  // ── Dinamik (Temaya Duyarlı) Renk Getters ──
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF212529);

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF8F9BB3)
      : const Color(0xFF495057);

  static Color textHint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF5A6178)
      : const Color(0xFF868E96);

  static Color cardBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1A1F36)
      : Colors.white;

  static Color inputFillColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1E2340)
      : const Color(0xFFF1F3F5);

  static Color inputBorderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF2A3055)
      : const Color(0xFFE9ECEF);

  static Color primaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? primaryBlue : yordamRed;

  static Color primaryColorLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? primaryBlueLight
      : const Color(0xFFFF4D6D);

  static LinearGradient primaryGradient(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return const LinearGradient(
        colors: [primaryBlue, accentCyan],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return const LinearGradient(
        colors: [yordamRed, Color(0xFFFF4D6D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  static LinearGradient backgroundGradient(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return const LinearGradient(
        colors: [Color(0xFF0A0E21), Color(0xFF141832)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
  }

  // ── ThemeData ──
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentCyan,
        surface: surfaceDark,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: scaffoldDark,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      inputDecorationTheme: _buildInputDecorationTheme(isDark: true),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      colorScheme: const ColorScheme.light(
        primary: yordamRed,
        secondary: Color(0xFFFF4D6D),
        surface: Colors.white,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF212529),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      inputDecorationTheme: _buildInputDecorationTheme(isDark: false),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme({
    required bool isDark,
  }) {
    final fill = isDark ? const Color(0xFF1E2340) : const Color(0xFFF1F3F5);
    final borderCol = isDark
        ? const Color(0xFF2A3055)
        : const Color(0xFFE9ECEF);
    final primary = isDark ? primaryBlue : yordamRed;
    final hint = isDark ? const Color(0xFF5A6178) : const Color(0xFF868E96);

    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderCol),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderCol),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: errorRed, width: 1.5),
      ),
      hintStyle: TextStyle(color: hint, fontSize: 14),
      prefixIconColor: isDark
          ? const Color(0xFF8F9BB3)
          : const Color(0xFF868E96),
      suffixIconColor: isDark
          ? const Color(0xFF8F9BB3)
          : const Color(0xFF868E96),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
