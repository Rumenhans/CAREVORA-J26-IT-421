import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class EcgLinePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  const EcgLinePainter({
    required this.progress,
    this.color = AppColors.primary,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h * 0.5;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, midY);

    // Segment 1: baseline
    path.lineTo(w * 0.20, midY);
    // P wave (small gentle bump)
    path.quadraticBezierTo(w * 0.23, midY - h * 0.15, w * 0.26, midY);
    // PR interval
    path.lineTo(w * 0.32, midY);
    // Q dip
    path.lineTo(w * 0.35, midY + h * 0.12);
    // R peak (tall spike)
    path.lineTo(w * 0.40, midY - h * 0.85);
    // S dip
    path.lineTo(w * 0.45, midY + h * 0.35);
    // ST segment
    path.lineTo(w * 0.50, midY);
    // T wave (medium broad bump)
    path.quadraticBezierTo(w * 0.58, midY - h * 0.30, w * 0.66, midY);
    // Return to baseline
    path.lineTo(w * 1.0, midY);

    // Extract animated portion based on progress
    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isNotEmpty) {
      final metric = pathMetrics.first;
      final extractLength = metric.length * progress.clamp(0.0, 1.0);
      final animatedPath = metric.extractPath(0, extractLength);
      canvas.drawPath(animatedPath, paint);

      // Glowing leading pulse dot
      if (progress > 0.05 && progress < 0.98) {
        final tangent = metric.getTangentForOffset(extractLength);
        if (tangent != null) {
          final dotGlow = Paint()
            ..color = color.withValues(alpha: 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
          canvas.drawCircle(tangent.position, 6, dotGlow);

          final dotSolid = Paint()
            ..color = color
            ..style = PaintingStyle.fill;
          canvas.drawCircle(tangent.position, 3, dotSolid);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant EcgLinePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
