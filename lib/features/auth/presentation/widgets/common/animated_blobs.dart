import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class AnimatedBlobs extends StatefulWidget {
  final Widget child;

  const AnimatedBlobs({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedBlobs> createState() => _AnimatedBlobsState();
}

class _AnimatedBlobsState extends State<AnimatedBlobs>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    if (disableAnimations) {
      return Stack(
        children: [
          _buildStaticBackground(),
          widget.child,
        ],
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * math.pi;

        return Stack(
          children: [
            // Blob 1: Lavender (Top Right)
            Positioned(
              top: -60 + math.sin(t) * 24,
              right: -40 + math.cos(t * 0.8) * 20,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.lilac.withValues(alpha: 0.55),
                      AppColors.lilac.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Blob 2: Warm Pink Blush (Bottom Left)
            Positioned(
              bottom: -40 + math.cos(t * 1.2) * 28,
              left: -50 + math.sin(t * 0.9) * 22,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentPink.withValues(alpha: 0.30),
                      AppColors.accentPink.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Blob 3: Primary Soft Purple Glow (Center Right)
            Positioned(
              top: 220 + math.sin(t * 0.7) * 20,
              right: 20 + math.cos(t * 1.1) * 18,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primarySoft.withValues(alpha: 0.65),
                      AppColors.primarySoft.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Subtle Dotted Pattern Overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _DottedGridPainter(),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }

  Widget _buildStaticBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lavenderBg,
              Colors.white,
              AppColors.lilac.withValues(alpha: 0.3),
            ],
          ),
        ),
      ),
    );
  }
}

class _DottedGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    const radius = 1.2;

    for (double x = 14; x < size.width; x += spacing) {
      for (double y = 14; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
