import 'package:flutter/material.dart';

class AppColors {
  static const paletteNames = [
    'Burger Bites',
    'Sizzling Crimson',
    'Golden Mustard Cheddar',
    'Emerald Mint Fresh',
    'Midnight Smoke Black',
    'Sweet Berry Bloom',
  ];

  static String _paletteName = 'Burger Bites';
  static bool _darkMode = false;

  static String get paletteName => _paletteName;
  static bool get isDarkMode => _darkMode;

  static void configure({String? palette, bool? darkMode}) {
    if (palette != null && paletteNames.contains(palette)) {
      _paletteName = palette;
    }
    if (darkMode != null) _darkMode = darkMode;
  }

  static Color get brandOrange => switch (_paletteName) {
    'Sizzling Crimson' => const Color(0xFFE53935),
    'Golden Mustard Cheddar' => const Color(0xFFE6A817),
    'Emerald Mint Fresh' => const Color(0xFF18A982),
    'Midnight Smoke Black' => const Color(0xFFD9894E),
    'Sweet Berry Bloom' => const Color(0xFFD64F79),
    _ => const Color(0xFFFF4F24),
  };
  static Color get brandOrangeDark => switch (_paletteName) {
    'Sizzling Crimson' => const Color(0xFFB91C1C),
    'Golden Mustard Cheddar' => const Color(0xFFC47E0D),
    'Emerald Mint Fresh' => const Color(0xFF117B67),
    'Midnight Smoke Black' => const Color(0xFFA95532),
    'Sweet Berry Bloom' => const Color(0xFFAA3157),
    _ => const Color(0xFFE84018),
  };
  static const Color brandAmber = Color(0xFFFFB247);
  static Color get brandRed => brandOrangeDark;
  static Color get brandGlow => brandOrange.withValues(alpha: .13);
  static Color get pageBackground =>
      _darkMode ? const Color(0xFF171311) : const Color(0xFFFAF7F5);
  static Color get surface =>
      _darkMode ? const Color(0xFF241D19) : const Color(0xFFFFFFFF);
  static Color get surfaceMuted =>
      _darkMode ? const Color(0xFF332720) : const Color(0xFFFFF0E9);
  static Color get surfaceElevated =>
      _darkMode ? const Color(0xFF2B221D) : const Color(0xFFFFFAF7);
  static Color get textPrimary =>
      _darkMode ? const Color(0xFFFFF7F1) : const Color(0xFF261C18);
  static Color get textSecondary =>
      _darkMode ? const Color(0xFFC0B1A7) : const Color(0xFF81756F);
  static Color get border =>
      _darkMode ? const Color(0xFF493A31) : const Color(0xFFEFE6E1);
  static const Color success = Color(0xFF24935B);
  static const Color warning = Color(0xFFF0A323);
  static const Color info = Color(0xFF3789C9);
  static const Color danger = Color(0xFFD83A32);
  static const Color darkSurface = Color(0xFF1C1715);
  static const Color darkSurfaceAlt = Color(0xFF2B211D);

  static LinearGradient get primaryButtonGradient => LinearGradient(
    colors: [brandOrange, brandRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroDarkGradient = LinearGradient(
    colors: [Color(0xFF2B1C16), Color(0xFF3A241B), Color(0xFF1C1411)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get warmSurfaceGradient => LinearGradient(
    colors: [surface, surfaceElevated],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
