import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Carevora Official Brand Logo Widget
/// Heart-shaped ring held by a gentle hand; inside it a purple adult figure embracing
/// a small pink child figure; two green leaves at top right of the heart.
class CarevoraLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool isSerif;

  const CarevoraLogo({
    super.key,
    this.size = 120,
    this.showWordmark = false,
    this.isSerif = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _CarevoraLogoPainter(),
        ),
        if (showWordmark) ...[
          const SizedBox(height: 14),
          Text(
            'CAREVORA',
            style: TextStyle(
              fontFamily: isSerif ? 'PlayfairDisplay' : 'Plus Jakarta Sans',
              fontSize: size * 0.24,
              fontWeight: FontWeight.w800,
              letterSpacing: 4.5,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ],
    );
  }
}

class _CarevoraLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. Soft Purple Glow halo behind emblem
    final glowPaint = Paint()
      ..color = AppColors.softLilac.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, w * 0.42, glowPaint);

    // 2. Heart-Shaped Ring outline (Primary Purple)
    final heartPath = Path();
    final hw = w * 0.68;
    final hh = h * 0.65;
    final hx = (w - hw) / 2;
    final hy = h * 0.12;

    heartPath.moveTo(hx + hw / 2, hy + hh * 0.85);
    // Left lobe
    heartPath.cubicTo(
      hx - hw * 0.15,
      hy + hh * 0.48,
      hx - hw * 0.05,
      hy,
      hx + hw / 2,
      hy + hh * 0.28,
    );
    // Right lobe
    heartPath.cubicTo(
      hx + hw * 1.05,
      hy,
      hx + hw * 1.15,
      hy + hh * 0.48,
      hx + hw / 2,
      hy + hh * 0.85,
    );

    final heartStroke = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(heartPath, heartStroke);

    // 3. Supporting Hand holding the base of heart
    final handPath = Path();
    final handY = h * 0.72;
    handPath.moveTo(w * 0.18, handY + h * 0.12);
    handPath.cubicTo(
      w * 0.32,
      handY + h * 0.22,
      w * 0.68,
      handY + h * 0.22,
      w * 0.82,
      handY + h * 0.12,
    );

    final handStroke = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.065
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(handPath, handStroke);

    // 4. Two Green Leaves at Top-Right of the heart
    final leafPaint = Paint()
      ..color = AppColors.leafGreen
      ..style = PaintingStyle.fill;

    // First Leaf
    final leaf1 = Path();
    final l1x = w * 0.74;
    final l1y = h * 0.16;
    leaf1.moveTo(l1x, l1y);
    leaf1.quadraticBezierTo(l1x + w * 0.12, l1y - h * 0.08, l1x + w * 0.16, l1y);
    leaf1.quadraticBezierTo(l1x + w * 0.08, l1y + h * 0.08, l1x, l1y);
    canvas.drawPath(leaf1, leafPaint);

    // Second smaller leaf
    final leaf2 = Path();
    final l2x = w * 0.82;
    final l2y = h * 0.23;
    leaf2.moveTo(l2x, l2y);
    leaf2.quadraticBezierTo(l2x + w * 0.11, l2y - h * 0.03, l2x + w * 0.12, l2y + h * 0.05);
    leaf2.quadraticBezierTo(l2x + w * 0.04, l2y + h * 0.06, l2x, l2y);
    canvas.drawPath(leaf2, leafPaint);

    // 5. Adult Purple Figure inside heart (left center)
    final adultHeadCenter = Offset(w * 0.43, h * 0.38);
    final adultPaint = Paint()..color = AppColors.primary;
    canvas.drawCircle(adultHeadCenter, w * 0.075, adultPaint);

    final adultBody = Path();
    adultBody.moveTo(w * 0.34, h * 0.64);
    adultBody.quadraticBezierTo(w * 0.34, h * 0.46, w * 0.43, h * 0.47);
    adultBody.quadraticBezierTo(w * 0.52, h * 0.46, w * 0.52, h * 0.64);
    adultBody.close();
    canvas.drawPath(adultBody, adultPaint);

    // 6. Embraced Child/Elderly Pink Figure (right center, nestled)
    final pinkPaint = Paint()..color = AppColors.accentPink;
    final pinkHeadCenter = Offset(w * 0.56, h * 0.44);
    canvas.drawCircle(pinkHeadCenter, w * 0.055, pinkPaint);

    final pinkBody = Path();
    pinkBody.moveTo(w * 0.50, h * 0.64);
    pinkBody.quadraticBezierTo(w * 0.50, h * 0.50, w * 0.56, h * 0.51);
    pinkBody.quadraticBezierTo(w * 0.62, h * 0.50, w * 0.62, h * 0.64);
    pinkBody.close();
    canvas.drawPath(pinkBody, pinkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
