import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

class SecureFooter extends StatelessWidget {
  const SecureFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Security Trust Indicators
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.lavenderBg.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.lilac.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.shieldCheck,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '256-bit Encrypted Connection • Confidential Eldercare Records',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDeep.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Staff Disclaimer
        const Text(
          'For authorized care home staff & clinical specialists only.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),

        // Compliance Placeholder & Legal links
        // TODO (Compliance Verification): Add verified HIPAA / GDPR / ISO audit badges upon official certification.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          children: [
            _buildLink(context, 'Privacy Policy'),
            _buildLink(context, 'Terms of Service'),
            _buildLink(context, 'Security Help'),
          ],
        ),
      ],
    );
  }

  Widget _buildLink(BuildContext context, String text) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$text link placeholder'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.muted,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
