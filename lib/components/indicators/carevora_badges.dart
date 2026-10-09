import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/enums.dart';

class StatusBadge extends StatelessWidget {
  final WellnessStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case WellnessStatus.lookingGood:
        bg = AppColors.positiveSoft;
        fg = AppColors.positive;
        label = 'Looking Good';
        icon = Icons.check_circle_outline_rounded;
        break;
      case WellnessStatus.stable:
        bg = AppColors.secondarySoft;
        fg = AppColors.secondary;
        label = 'Stable';
        icon = Icons.health_and_safety_outlined;
        break;
      case WellnessStatus.needsAttention:
        bg = AppColors.warningSoft;
        fg = AppColors.warning;
        label = 'Needs Attention';
        icon = Icons.info_outline_rounded;
        break;
      case WellnessStatus.letCheckIn:
        bg = AppColors.criticalSoft;
        fg = AppColors.critical;
        label = 'Check-in Needed';
        icon = Icons.warning_amber_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class RiskBadge extends StatelessWidget {
  final RiskLevel riskLevel;

  const RiskBadge({super.key, required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (riskLevel) {
      case RiskLevel.low:
        bg = AppColors.positiveSoft;
        fg = AppColors.positive;
        label = 'Low Risk';
        break;
      case RiskLevel.moderate:
        bg = AppColors.warningSoft;
        fg = AppColors.warning;
        label = 'Moderate Risk';
        break;
      case RiskLevel.high:
        bg = AppColors.criticalSoft;
        fg = AppColors.critical;
        label = 'High Risk';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class TrajectoryBadge extends StatelessWidget {
  final TrajectoryDirection trajectory;

  const TrajectoryBadge({super.key, required this.trajectory});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String text;

    switch (trajectory) {
      case TrajectoryDirection.improving:
        color = AppColors.positive;
        icon = Icons.trending_up_rounded;
        text = 'Improving';
        break;
      case TrajectoryDirection.stable:
        color = AppColors.secondary;
        icon = Icons.trending_flat_rounded;
        text = 'Stable';
        break;
      case TrajectoryDirection.increasingRisk:
        color = AppColors.warning;
        icon = Icons.trending_down_rounded;
        text = 'Declining';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
