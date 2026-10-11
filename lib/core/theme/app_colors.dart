import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primary = Color(0xFF6C3FC5);
  static const Color primaryDeep = Color(0xFF5B2FB0);
  static const Color primarySoft = Color(0xFFEDE9FE);

  // Neutral / Text
  static const Color navy = Color(0xFF1A1445);
  static const Color body = Color(0xFF5B5A6E);
  static const Color muted = Color(0xFF8E8CA3);

  // Backgrounds & Surface
  static const Color lavenderBg = Color(0xFFF4F0FF);
  static const Color lilac = Color(0xFFE9E1FF);
  static const Color page = Color(0xFFF8F7FC);
  static const Color dashboardBg = Color(0xFFF5F6FB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFECE8F7);
  static const Color surfaceSecondary = Color(0xFFFAF9FD);

  // Accents
  static const Color accentPink = Color(0xFFE88BC4);
  static const Color leafGreen = Color(0xFF6CC24A);

  // Clinical Risk Thresholds
  static const Color riskLow = Color(0xFF22C55E);
  static const Color riskLowBg = Color(0xFFE7F8EE);

  static const Color riskModerate = Color(0xFFF59E0B);
  static const Color riskModerateBg = Color(0xFFFEF3DC);

  static const Color riskHigh = Color(0xFFEF4444);
  static const Color riskHighBg = Color(0xFFFDE8E8);

  // Auth Background & Frosted Glass Tokens
  static final Color scrimTop = const Color(0xFF1A1445).withValues(alpha: 0.55);
  static final Color scrimMiddle = const Color(0xFF5B2FB0).withValues(alpha: 0.35);
  static final Color scrimBottom = const Color(0xFF1A1445).withValues(alpha: 0.70);
  static final Color glassWhite = Colors.white.withValues(alpha: 0.86);
  static final Color glassBorder = Colors.white.withValues(alpha: 0.60);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pageGradient = LinearGradient(
    colors: [lavenderBg, Color(0xFFFFFFFF), Color(0xFFFDF2F8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final LinearGradient authScrimGradient = LinearGradient(
    colors: [
      const Color(0xFF1A1445).withValues(alpha: 0.55),
      const Color(0xFF5B2FB0).withValues(alpha: 0.35),
      const Color(0xFF1A1445).withValues(alpha: 0.70),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

