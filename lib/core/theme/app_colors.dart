import 'package:flutter/material.dart';

/// Strict Brand Design System for CAREVORA
/// "Compassionate Care, Smarter Tomorrow"
/// AI-powered wellness monitoring and early risk detection system for elderly care homes.
class AppColors {
  AppColors._();

  // Core Brand Purple & Violet
  static const Color primary = Color(0xFF6C3FC5); // Buttons, active states, links, headings accent
  static const Color primaryDark = Color(0xFF5B2FB0); // Deep Violet: hover, gradient end, footer band
  static const Color primaryLight = Color(0xFF8B5CF6); // Lighter purple tint
  static const Color primarySoft = Color(0xFFFAF8FF); // Light lavender input fill
  static const Color softLilac = Color(0xFFE9E1FF); // Soft Lilac accent / border
  static const Color lavenderBackground = Color(0xFFF4F0FF); // Ambient watercolor tint

  // Secondary Accents (Mapped into cohesive Violet/Lilac brand palette)
  static const Color secondary = Color(0xFF5B2FB0); // Deep Violet accent
  static const Color secondarySoft = Color(0xFFE9E1FF); // Soft Lilac tint

  // Typographic Colors
  static const Color textPrimary = Color(0xFF1A1445); // Dark Navy Headings
  static const Color textSecondary = Color(0xFF5B5A6E); // Body Gray Text
  static const Color textTertiary = Color(0xFF8E8CA3); // Muted Label Text
  static const Color textLight = Color(0xFFFFFFFF);

  // Backgrounds & Surface Cards
  static const Color background = Color(0xFFF8F7FC); // Page Off-white
  static const Color surface = Color(0xFFFFFFFF); // Card White
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFFAF8FF); // Input & secondary fill

  // Logo & Decorative Accents
  static const Color accentPink = Color(0xFFE88BC4); // Logo heart / child figure accent
  static const Color leafGreen = Color(0xFF6CC24A); // Logo leaves accent

  // Clinical Risk State Tints
  static const Color positive = Color(0xFF22C55E); // Low Risk = Green #22C55E
  static const Color positiveSoft = Color(0xFFE7F8EE); // Low Risk BG

  static const Color warning = Color(0xFFF59E0B); // Moderate Risk = Amber #F59E0B
  static const Color warningSoft = Color(0xFFFEF3DC); // Moderate Risk BG

  static const Color critical = Color(0xFFEF4444); // High Risk = Red #EF4444
  static const Color criticalSoft = Color(0xFFFDE8E8); // High Risk BG

  // Borders & Dividers
  static const Color border = Color(0xFFECE8F7); // Card 1px border
  static const Color borderLight = Color(0xFFF4F0FF); // Light border
  static const Color borderInput = Color(0xFFE4DEF5); // Input 1px border
  static const Color borderCard = Color(0xFFE9E1FF); // 2px lavender-purple card border

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C3FC5), Color(0xFF5B2FB0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF6C3FC5), Color(0xFF5B2FB0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient watercolorBackground = LinearGradient(
    colors: [Color(0xFFF4F0FF), Color(0xFFFFFFFF), Color(0xFFFDF2F8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softWellnessGradient = LinearGradient(
    colors: [Color(0xFFFAF8FF), Color(0xFFF4F0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Soft Purple Tinted Shadow
  static List<BoxShadow> get cardShadow => [
        const BoxShadow(
          color: Color.fromRGBO(108, 63, 197, 0.10),
          offset: Offset(0, 8),
          blurRadius: 24,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        const BoxShadow(
          color: Color.fromRGBO(108, 63, 197, 0.25),
          offset: Offset(0, 6),
          blurRadius: 16,
          spreadRadius: 0,
        ),
      ];
}
