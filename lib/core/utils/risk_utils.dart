import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum RiskTier {
  low,
  moderate,
  high;

  String get label {
    switch (this) {
      case RiskTier.low:
        return 'Low';
      case RiskTier.moderate:
        return 'Moderate';
      case RiskTier.high:
        return 'High';
    }
  }

  Color get color {
    switch (this) {
      case RiskTier.low:
        return AppColors.riskLow;
      case RiskTier.moderate:
        return AppColors.riskModerate;
      case RiskTier.high:
        return AppColors.riskHigh;
    }
  }

  Color get bgColor {
    switch (this) {
      case RiskTier.low:
        return AppColors.riskLowBg;
      case RiskTier.moderate:
        return AppColors.riskModerateBg;
      case RiskTier.high:
        return AppColors.riskHighBg;
    }
  }
}

class RiskUtils {
  RiskUtils._();

  static RiskTier getTier(double score) {
    if (score < 0.40) return RiskTier.low;
    if (score < 0.70) return RiskTier.moderate;
    return RiskTier.high;
  }

  static String formatScore(double score) {
    return score.toStringAsFixed(2);
  }
}
