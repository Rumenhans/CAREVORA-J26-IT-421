import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/caregiver_hands_illustration.dart';
import '../../../../shared/widgets/carevora_logo.dart';

class LoginMobileHeader extends StatelessWidget {
  const LoginMobileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.lavenderBg,
            AppColors.page,
          ],
        ),
      ),
      child: Column(
        children: [
          // Logo Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CarevoraLogo(
                variant: LogoVariant.iconOnly,
                size: 32,
              ),
              SizedBox(width: 10),
              CarevoraLogo(
                variant: LogoVariant.wordmarkOnly,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mobile Eldercare Photo
          Container(
            width: 140,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/landing/login_caregiver_resident.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.white,
                  child: const Center(
                    child: CaregiverHandsIllustration(size: 60),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tagline
          const Text(
            'Compassionate Care, Smarter Tomorrow',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'AI-Powered Wellness Monitoring for Eldercare',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.body,
            ),
          ),
        ],
      ),
    );
  }
}
