import 'package:flutter/material.dart';
import '../../core/utils/risk_utils.dart';

class RiskBadge extends StatelessWidget {
  final double score;
  final String? customLabel;

  const RiskBadge({
    super.key,
    required this.score,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final tier = RiskUtils.getTier(score);
    final text = customLabel ?? tier.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tier.bgColor,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: tier.color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: tier.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tier.color,
            ),
          ),
        ],
      ),
    );
  }
}
