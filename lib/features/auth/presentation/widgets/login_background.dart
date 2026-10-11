import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../core/theme/app_colors.dart';

/// Full-bleed background layer with responsive photo, brand scrim gradient,
/// and slow drifting ambient blobs.
class LoginBackground extends StatefulWidget {
  final Widget child;

  const LoginBackground({
    super.key,
    required this.child,
  });

  @override
  State<LoginBackground> createState() => _LoginBackgroundState();
}

class _LoginBackgroundState extends State<LoginBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _blobController;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return ResponsiveBuilder(
      mobile: (context) => _buildStack(
        isDesktop: false,
        disableAnimations: disableAnimations,
      ),
      tablet: (context) => _buildStack(
        isDesktop: false,
        disableAnimations: disableAnimations,
      ),
      desktop: (context) => _buildStack(
        isDesktop: true,
        disableAnimations: disableAnimations,
      ),
    );
  }

  Widget _buildStack({
    required bool isDesktop,
    required bool disableAnimations,
  }) {
    final assetPath = isDesktop
        ? 'assets/images/auth/login_bg_desktop.jpg'
        : 'assets/images/auth/login_bg_mobile.jpg';

    final imageAlignment = isDesktop
        ? const Alignment(-0.35, -0.2) // keep faces visible on desktop
        : const Alignment(0.0, -0.4);   // keep faces visible in portrait mobile

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Full-screen Caregiver Photo
        Semantics(
          label: "A caregiver holding an elderly resident's hands",
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            alignment: imageAlignment,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.pageGradient,
                ),
              );
            },
          ),
        ),

        // 2. Brand Scrim Overlay (WCAG AA Compliance)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.navy.withValues(alpha: 0.60),
                AppColors.primaryDeep.withValues(alpha: 0.40),
                AppColors.navy.withValues(alpha: 0.75),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // 3. Subtle Ambient Floating Blobs & Sparkles
        if (!disableAnimations)
          AnimatedBuilder(
            animation: _blobController,
            builder: (context, child) {
              final t = _blobController.value;
              final sinT = math.sin(t * math.pi * 2);
              final cosT = math.cos(t * math.pi * 2);

              return Stack(
                children: [
                  // Top-left Lilac Glow
                  Positioned(
                    top: -60 + (sinT * 25),
                    left: -40 + (cosT * 20),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.lilac.withValues(alpha: 0.12),
                      ),
                    ),
                  ),

                  // Bottom-right Warm Pink Glow
                  Positioned(
                    bottom: -80 + (cosT * 30),
                    right: -50 + (sinT * 25),
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentPink.withValues(alpha: 0.10),
                      ),
                    ),
                  ),

                  // Mid-left subtle primary glow
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.4 + (sinT * 15),
                    left: 20 + (cosT * 15),
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primarySoft.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        // 4. Foreground Content
        widget.child,
      ],
    );
  }
}
