import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Decorative Silhouette of a caregiver gently holding an elderly person's hands
/// surrounded by subtle organic leaves and watercolor flora.
class CaregiverHandsIllustration extends StatelessWidget {
  final double width;
  final double height;

  const CaregiverHandsIllustration({
    super.key,
    this.width = 320,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _CaregiverHandsPainter(),
    );
  }
}

class _CaregiverHandsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Translucent lavender watercolor glow behind hands
    final auraPaint = Paint()
      ..color = AppColors.softLilac.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawOval(Rect.fromLTWH(w * 0.15, h * 0.2, w * 0.7, h * 0.7), auraPaint);

    final strokePaint = Paint()
      ..color = AppColors.primaryDark.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // Outer cupped caregiver hand (left wrist reaching up)
    final caregiverHand = Path();
    caregiverHand.moveTo(w * 0.1, h * 0.95);
    caregiverHand.cubicTo(w * 0.22, h * 0.75, w * 0.32, h * 0.58, w * 0.44, h * 0.52);
    // gentle fingers supporting
    caregiverHand.cubicTo(w * 0.55, h * 0.48, w * 0.65, h * 0.55, w * 0.72, h * 0.66);
    caregiverHand.cubicTo(w * 0.60, h * 0.82, w * 0.40, h * 0.92, w * 0.26, h * 0.98);
    caregiverHand.close();

    canvas.drawPath(caregiverHand, fillPaint);
    canvas.drawPath(caregiverHand, strokePaint);

    // Elderly gently resting hand (top right resting inside cupped palm)
    final elderlyHand = Path();
    elderlyHand.moveTo(w * 0.88, h * 0.35);
    elderlyHand.cubicTo(w * 0.75, h * 0.42, w * 0.62, h * 0.48, w * 0.52, h * 0.56);
    elderlyHand.cubicTo(w * 0.45, h * 0.62, w * 0.42, h * 0.72, w * 0.48, h * 0.75);
    elderlyHand.cubicTo(w * 0.58, h * 0.76, w * 0.68, h * 0.65, w * 0.78, h * 0.52);
    elderlyHand.close();

    final elderlyStroke = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(elderlyHand, fillPaint);
    canvas.drawPath(elderlyHand, elderlyStroke);

    // Soft leaf silhouettes flanking the base
    final leafPaint = Paint()
      ..color = AppColors.leafGreen.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    // Left botanical twig
    final leaf1 = Path();
    leaf1.moveTo(w * 0.04, h * 0.9);
    leaf1.quadraticBezierTo(w * 0.08, h * 0.65, w * 0.16, h * 0.68);
    leaf1.quadraticBezierTo(w * 0.12, h * 0.88, w * 0.04, h * 0.9);
    canvas.drawPath(leaf1, leafPaint);

    // Right botanical twig
    final leaf2 = Path();
    leaf2.moveTo(w * 0.94, h * 0.88);
    leaf2.quadraticBezierTo(w * 0.88, h * 0.66, w * 0.80, h * 0.72);
    leaf2.quadraticBezierTo(w * 0.85, h * 0.90, w * 0.94, h * 0.88);
    canvas.drawPath(leaf2, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
