import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import 'common/glass_container.dart';

/// Desktop left hero column showcasing the Carevora clinical vision.
class LoginDesktopHero extends StatelessWidget {
  const LoginDesktopHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Live Caregiver Heart Pulse Chip
        GlassContainer(
          borderRadius: 20,
          blur: 12,
          color: Colors.white.withValues(alpha: 0.16),
          borderColor: Colors.white.withValues(alpha: 0.35),
          borderWidth: 1.2,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          boxShadow: const [],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.heartPulse,
                size: 16,
                color: AppColors.accentPink,
              ),
              const SizedBox(width: 8),
              const Text(
                'AI-Powered Eldercare Intelligence',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Bold Headline
        const Text(
          'Care that never\nlooks away.',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.15,
            letterSpacing: -0.8,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 4),
                blurRadius: 16,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Subtitle
        Text(
          'Real-time resident risk monitoring, behavioral insights, and compassionate clinical decision support for high-quality care homes.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.88),
            height: 1.55,
          ),
        ),
        const SizedBox(height: 32),

        // 3 Feature Checkpoints
        _buildCheckItem(
          title: 'Early risk alerts for every resident',
          description: 'Continuous physiological and behavioral trend detection.',
        ),
        const SizedBox(height: 16),
        _buildCheckItem(
          title: 'Explainable AI insights',
          description: 'Clear clinical reasoning backed by multi-modal sensor inputs.',
        ),
        const SizedBox(height: 16),
        _buildCheckItem(
          title: 'Built for caregivers',
          description: 'Intuitive interface that reduces documentation burden.',
        ),
        const SizedBox(height: 36),

        // Bottom Trust strip
        Row(
          children: [
            Icon(
              LucideIcons.shieldCheck,
              size: 18,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 8),
            Text(
              'HIPAA & GDPR Ready Architecture • Multi-Tenant Care Security',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckItem({
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.leafGreen.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.leafGreen.withValues(alpha: 0.6),
              width: 1.2,
            ),
          ),
          child: const Icon(
            Icons.check,
            size: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
