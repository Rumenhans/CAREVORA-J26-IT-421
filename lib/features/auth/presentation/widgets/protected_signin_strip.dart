import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

/// Security and protection strip under the LOGIN form:
/// "Encrypted connection", "Data stays confidential", "Auto sign-out when idle".
class ProtectedSignInStrip extends StatelessWidget {
  const ProtectedSignInStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.lavenderBg.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.lilac.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPill(
                icon: LucideIcons.lock,
                label: 'Encrypted\nconnection',
              ),
              _buildDivider(),
              _buildPill(
                icon: LucideIcons.shieldCheck,
                label: 'Data stays\nconfidential',
              ),
              _buildDivider(),
              _buildPill(
                icon: LucideIcons.clock,
                label: 'Auto sign-out\nwhen idle',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.primary,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          textAlign: TextAlign.left,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            height: 1.15,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 18,
      width: 1,
      color: AppColors.lilac,
    );
  }
}
