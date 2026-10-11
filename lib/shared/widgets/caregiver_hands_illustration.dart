import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CaregiverHandsIllustration extends StatelessWidget {
  final double size;

  const CaregiverHandsIllustration({super.key, this.size = 240});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.7,
      child: CustomPaint(
        painter: _HandsPainter(),
      ),
    );
  }
}

class _HandsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    // Outer cupped palm
    final path = Path();
    path.moveTo(w * 0.15, h * 0.8);
    path.cubicTo(w * 0.25, h * 0.45, w * 0.4, h * 0.25, w * 0.6, h * 0.35);
    path.cubicTo(w * 0.75, h * 0.45, w * 0.85, h * 0.65, w * 0.8, h * 0.85);
    path.cubicTo(w * 0.6, h * 0.95, w * 0.35, h * 0.92, w * 0.15, h * 0.8);

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Inner supporting hand
    final path2 = Path();
    path2.moveTo(w * 0.3, h * 0.75);
    path2.cubicTo(w * 0.38, h * 0.55, w * 0.5, h * 0.45, w * 0.68, h * 0.5);
    canvas.drawPath(path2, paint);

    // Small botanical leaf accent
    final leafPaint = Paint()
      ..color = AppColors.leafGreen.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final leaf = Path();
    leaf.moveTo(w * 0.7, h * 0.25);
    leaf.quadraticBezierTo(w * 0.78, h * 0.15, w * 0.85, h * 0.22);
    leaf.quadraticBezierTo(w * 0.78, h * 0.32, w * 0.7, h * 0.25);
    canvas.drawPath(leaf, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
