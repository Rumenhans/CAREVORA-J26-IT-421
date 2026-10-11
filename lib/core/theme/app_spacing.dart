import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double button = 10.0;
  static const double card = 16.0;
  static const double cardLg = 20.0;
  static const double loginCard = 36.0;
  static const double pill = 9999.0;
}

class AppShadows {
  AppShadows._();

  static final BoxShadow card = BoxShadow(
    color: const Color(0xFF6C3FC5).withValues(alpha: 0.06),
    blurRadius: 20,
    offset: const Offset(0, 4),
  );

  static final BoxShadow glow = BoxShadow(
    color: const Color(0xFF6C3FC5).withValues(alpha: 0.12),
    blurRadius: 28,
    offset: const Offset(0, 8),
  );
}
