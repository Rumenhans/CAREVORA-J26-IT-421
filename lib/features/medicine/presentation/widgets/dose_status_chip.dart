import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DoseStatusChip extends StatelessWidget {
  final String status;
  final String? lateLabel;

  const DoseStatusChip({
    super.key,
    required this.status,
    this.lateLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.primarySoft;
    Color fg = AppColors.primary;
    IconData icon = Icons.schedule;
    String label = status.toUpperCase();

    switch (status) {
      case 'given':
        bg = AppColors.riskLowBg;
        fg = AppColors.riskLow;
        icon = Icons.check_circle_rounded;
        label = 'GIVEN';
        break;
      case 'overdue':
        bg = AppColors.riskHighBg;
        fg = AppColors.riskHigh;
        icon = Icons.error_rounded;
        label = lateLabel ?? 'OVERDUE';
        break;
      case 'pending':
        bg = AppColors.riskModerateBg;
        fg = AppColors.riskModerate;
        icon = Icons.pending_rounded;
        label = 'PENDING';
        break;
      case 'upcoming':
        bg = AppColors.dashboardBg;
        fg = AppColors.muted;
        icon = Icons.access_time_rounded;
        label = 'UPCOMING';
        break;
      case 'refused':
      case 'held':
      case 'missed':
        bg = AppColors.riskHighBg;
        fg = AppColors.riskHigh;
        icon = Icons.cancel_rounded;
        label = status.toUpperCase();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }
}
