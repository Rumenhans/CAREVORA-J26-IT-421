import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CitySkylineIllustration extends StatelessWidget {
  final double height;

  const CitySkylineIllustration({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _CitySkylinePainter(),
      ),
    );
  }
}

class _CitySkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bgBuildingPaint = Paint()
      ..color = const Color(0xFFDED8F3)
      ..style = PaintingStyle.fill;

    final frontBuildingPaint = Paint()
      ..color = const Color(0xFFC7BCED)
      ..style = PaintingStyle.fill;

    // Distant soft buildings
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.05, h * 0.3, w * 0.1, h * 0.7), const Radius.circular(4)),
      bgBuildingPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.2, h * 0.2, w * 0.12, h * 0.8), const Radius.circular(4)),
      bgBuildingPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.45, h * 0.25, w * 0.14, h * 0.75), const Radius.circular(4)),
      bgBuildingPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.7, h * 0.35, w * 0.12, h * 0.65), const Radius.circular(4)),
      bgBuildingPaint,
    );

    // Foreground buildings
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.12, h * 0.45, w * 0.1, h * 0.55), const Radius.circular(4)),
      frontBuildingPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.34, h * 0.4, w * 0.13, h * 0.6), const Radius.circular(4)),
      frontBuildingPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.58, h * 0.5, w * 0.14, h * 0.5), const Radius.circular(4)),
      frontBuildingPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.8, h * 0.42, w * 0.15, h * 0.58), const Radius.circular(4)),
      frontBuildingPaint,
    );

    // Warm Sun / Ambient glow
    final sunPaint = Paint()
      ..color = AppColors.accentPink.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.88, h * 0.25), 24, sunPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
