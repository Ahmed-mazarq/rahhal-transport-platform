import 'package:flutter/material.dart';

/// Driver Experience Design Tokens (Part 1 Design System)
class DriverTokens {
  DriverTokens._();

  // Colors
  static const Color primaryNavy = Color(0xFF0B1F3A);
  static const Color accentGold = Color(0xFFF5A623);
  static const Color backgroundLight = Color(0xFFF7F8FA);
  static const Color lightBackground = backgroundLight;
  static const Color cardDark = Color(0xFF1E1E1E);

  // Semantics
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57F17);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);

  static const Color semanticSuccess = success;
  static const Color semanticWarning = warning;
  static const Color semanticError = error;
  static const Color semanticInfo = info;

  // Spacing (8-point system)
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;

  static const double spaceXs = s4;
  static const double spaceSm = s8;
  static const double spaceMd = s16;
  static const double spaceLg = s24;
  static const double spaceXl = s32;

  // Corner Radii
  static const double radiusSmall = 12.0;
  static const double radiusCard = 18.0;
  static const double radiusHero = 24.0;
  static const double radiusStadium = 999.0;
  static const double radiusPill = radiusStadium;

  static BorderRadius get borderSmall => BorderRadius.circular(radiusSmall);
  static BorderRadius get borderCard => BorderRadius.circular(radiusCard);
  static BorderRadius get borderHero => BorderRadius.circular(radiusHero);
  static BorderRadius get borderStadium => BorderRadius.circular(radiusStadium);

  // Subtle Card Shadow
  static List<BoxShadow> cardShadow(bool isDark) => [
    BoxShadow(
      color: isDark
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
