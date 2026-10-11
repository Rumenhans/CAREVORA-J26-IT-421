import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/caregiver_hands_illustration.dart';
import '../../../../shared/widgets/carevora_logo.dart';
import 'common/animated_blobs.dart';
import 'common/ecg_line_painter.dart';
import 'common/floating_glass_card.dart';
import 'common/rotating_message.dart';

class LoginBrandPanel extends StatefulWidget {
  const LoginBrandPanel({super.key});

  @override
  State<LoginBrandPanel> createState() => _LoginBrandPanelState();
}

class _LoginBrandPanelState extends State<LoginBrandPanel>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _ecgController;

  static const List<String> _reassurances = [
    'Every resident matters.',
    'Early signs, caught early.',
    'Supporting caregivers, every day.',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ecgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return AnimatedBlobs(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CarevoraLogo(
                      variant: LogoVariant.iconOnly,
                      size: 40,
                    ),
                    SizedBox(width: 14),
                    CarevoraLogo(
                      variant: LogoVariant.wordmarkOnly,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Heart Divider
                _buildHeartDivider(),
                const SizedBox(height: 22),

                // Tagline & Description
                const Text(
                  'Compassionate Care, Smarter Tomorrow',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: -0.4,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'AI-Powered Wellness Monitoring and Early Risk Detection System for Elderly Care Homes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.body,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Central Hero Eldercare Photo Frame with Glowing Badge Overlays
                SizedBox(
                  width: 380,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Lavender Backing Glow Box
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          width: 360,
                          height: 240,
                          decoration: BoxDecoration(
                            color: AppColors.lilac.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),

                      // Main Real Photo
                      Container(
                        width: 360,
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.14),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/images/landing/login_caregiver_resident.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: AppColors.lavenderBg,
                              child: const Center(
                                child: CaregiverHandsIllustration(size: 130),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Floating Glass Badge 1: Early risk alerts
                      Positioned(
                        top: -12,
                        left: -12,
                        child: const FloatingGlassBadge(
                          icon: LucideIcons.shieldAlert,
                          title: 'Early risk alerts',
                          iconColor: AppColors.accentPink,
                        ),
                      ),

                      // Floating Glass Badge 2: Explainable AI
                      Positioned(
                        bottom: -12,
                        right: -12,
                        child: const FloatingGlassBadge(
                          icon: LucideIcons.sparkles,
                          title: 'Explainable AI insights',
                          iconColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Animated ECG Line across the bottom of the brand panel
                SizedBox(
                  height: 36,
                  width: 280,
                  child: AnimatedBuilder(
                    animation: _ecgController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: EcgLinePainter(
                          progress: disableAnimations
                              ? 1.0
                              : _ecgController.value,
                          color: AppColors.primary,
                          strokeWidth: 2.0,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Auto-advancing rotating reassurance message
                const RotatingMessage(messages: _reassurances),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeartDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.lilac.withValues(alpha: 0.0),
                AppColors.primary.withValues(alpha: 0.5),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.favorite_rounded,
            size: 16,
            color: AppColors.accentPink.withValues(alpha: 0.9),
          ),
        ),
        Container(
          width: 48,
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.5),
                AppColors.lilac.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
