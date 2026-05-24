import 'package:flutter/material.dart';

class AppTheme {
  // ── Color Palette ───────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A1A2E);       // Deep navy-black
  static const Color accent = Color(0xFFE8A045);        // Warm amber / gold
  static const Color accentLight = Color(0xFFFFF3E0);   // Amber tint bg
  static const Color background = Color(0xFFF8F8F8);    // Off-white
  static const Color surface = Color(0xFFFFFFFF);       // Pure white cards
  static const Color textPrimary = Color(0xFF1A1A2E);   // Same as primary
  static const Color textSecondary = Color(0xFF7A7A8C); // Muted gray
  static const Color textTertiary = Color(0xFFB0B0C0);  // Light muted
  static const Color divider = Color(0xFFEEEEF2);       // Subtle divider
  static const Color starColor = Color(0xFFFFBB3B);     // Star yellow
  static const Color success = Color(0xFF27AE60);        // Green
  static const Color warning = Color(0xFFF39C12);        // Orange

  // ── Typography ──────────────────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.6,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textTertiary,
    letterSpacing: 0.2,
  );

  // ── Shadows ──────────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF1A1A2E).withOpacity(0.06),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: const Color(0xFF1A1A2E).withOpacity(0.03),
          blurRadius: 6,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: accent.withOpacity(0.35),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
      ];

  // ── Theme Data ────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: accent,
          surface: surface,
          background: background,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: divider, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: divider, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          hintStyle: const TextStyle(color: textTertiary, fontSize: 15),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: textPrimary,
          unselectedLabelColor: textTertiary,
          indicatorColor: accent,
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFEEEEFC),
          secondary: accent,
          surface: Color(0xFF1A1A26),
          background: Color(0xFF0F0F17),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A26),
          foregroundColor: Color(0xFFEEEEFC),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFFEEEEFC),
            letterSpacing: -0.2,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEEEEFC),
            foregroundColor: const Color(0xFF0F0F17),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1A26),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF252538), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF252538), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEEEEFC), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          hintStyle: const TextStyle(color: Color(0xFF555570), fontSize: 15),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Color(0xFF555570),
          indicatorColor: accent,
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      );
}

// ── BuildContext color extension ──────────────────────────────────────────────
extension AppColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg    => isDark ? const Color(0xFF0F0F17) : AppTheme.background;
  Color get surf  => isDark ? const Color(0xFF1A1A26) : AppTheme.surface;
  Color get tp    => isDark ? const Color(0xFFEEEEFC) : AppTheme.textPrimary;
  Color get ts    => isDark ? const Color(0xFF8888A4) : AppTheme.textSecondary;
  Color get tt    => isDark ? const Color(0xFF555570) : AppTheme.textTertiary;
  Color get div   => isDark ? const Color(0xFF252538) : AppTheme.divider;
  Color get pri   => isDark ? const Color(0xFFEEEEFC) : AppTheme.primary;
  List<BoxShadow> get shadow => isDark
      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))]
      : AppTheme.cardShadow;
}