import 'package:flutter/material.dart';

class AppColors {
  static const Color brandOrange = Color(0xFFFF4F24);
  static const Color brandOrangeDark = Color(0xFFE84018);
  static const Color brandAmber = Color(0xFFFFB247);
  static const Color brandRed = Color(0xFFEF2F2B);
  static const Color brandGlow = Color(0xFFFFE5D8);
  static const Color pageBackground = Color(0xFFFAF7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFFFF0E9);
  static const Color surfaceElevated = Color(0xFFFFFAF7);
  static const Color textPrimary = Color(0xFF261C18);
  static const Color textSecondary = Color(0xFF81756F);
  static const Color border = Color(0xFFEFE6E1);
  static const Color success = Color(0xFF24935B);
  static const Color warning = Color(0xFFF0A323);
  static const Color info = Color(0xFF3789C9);
  static const Color danger = Color(0xFFD83A32);
  static const Color darkSurface = Color(0xFF1C1715);
  static const Color darkSurfaceAlt = Color(0xFF2B211D);

  static const LinearGradient primaryButtonGradient = LinearGradient(
    colors: [brandOrange, brandRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroDarkGradient = LinearGradient(
    colors: [Color(0xFF2B1C16), Color(0xFF3A241B), Color(0xFF1C1411)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmSurfaceGradient = LinearGradient(
    colors: [surface, surfaceElevated],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
