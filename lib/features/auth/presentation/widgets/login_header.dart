import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/carevora_logo.dart';
import 'common/glass_container.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Inverted White Carevora Logo
        const CarevoraLogo(
          variant: LogoVariant.full,
          size: 38,
          isDark: true,
        ),
        const SizedBox(height: 12),

        // Subtitle with 80% opacity
        Text(
          'AI-Powered Wellness Monitoring for Eldercare',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.85),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),

        // Glass pill: "Trusted care. Protected data." + Caregiver-first chip
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            GlassContainer(
              borderRadius: 20,
              blur: 10,
              color: Colors.white.withValues(alpha: 0.15),
              borderColor: Colors.white.withValues(alpha: 0.35),
              borderWidth: 1,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              boxShadow: const [],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.shieldCheck,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Trusted care. Protected data.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ),
            GlassContainer(
              borderRadius: 20,
              blur: 10,
              color: AppColors.accentPink.withValues(alpha: 0.20),
              borderColor: Colors.white.withValues(alpha: 0.35),
              borderWidth: 1,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              boxShadow: const [],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.heartHandshake,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Caregiver-first',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
