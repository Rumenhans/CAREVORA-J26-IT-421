import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum LogoVariant {
  full,
  iconOnly,
  wordmarkOnly,
}

class CarevoraLogo extends StatelessWidget {
  final LogoVariant variant;
  final double size;
  final bool isDark;

  const CarevoraLogo({
    super.key,
    this.variant = LogoVariant.full,
    this.size = 40,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case LogoVariant.iconOnly:
        return _buildIcon();
      case LogoVariant.wordmarkOnly:
        return _buildWordmark();
      case LogoVariant.full:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIcon(),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CAREVORA',
                  style: AppTextStyles.wordmarkSmall.copyWith(
                    fontSize: size * 0.55,
                    color: isDark ? Colors.white : AppColors.navy,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  'Compassionate Care, Smarter Tomorrow',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: (size * 0.24).clamp(10.0, 13.0),
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildIcon() {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CarevoraLogoPainter(),
      ),
    );
  }

  Widget _buildWordmark() {
    return Text(
      'CAREVORA',
      style: AppTextStyles.wordmark.copyWith(
        fontSize: size * 0.8,
        color: isDark ? Colors.white : AppColors.navy,
      ),
    );
  }
}

class _CarevoraLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer Heart / Cupping Hand shape
    final heartPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.12
      ..strokeCap = StrokeCap.round;

    final heartPath = Path();
    heartPath.moveTo(w * 0.5, h * 0.88);
    heartPath.cubicTo(w * 0.1, h * 0.65, w * 0.05, h * 0.3, w * 0.32, h * 0.22);
    heartPath.cubicTo(w * 0.44, h * 0.18, w * 0.5, h * 0.32, w * 0.5, h * 0.38);
    heartPath.cubicTo(w * 0.5, h * 0.32, w * 0.56, h * 0.18, w * 0.68, h * 0.22);
    heartPath.cubicTo(w * 0.95, h * 0.3, w * 0.9, h * 0.65, w * 0.5, h * 0.88);
    canvas.drawPath(heartPath, heartPaint);

    // Inner Adult Figure (Purple)
    final adultPaint = Paint()
      ..color = AppColors.primaryDeep
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.44, h * 0.45), w * 0.12, adultPaint);

    // Inner Small Child / Senior Figure (Pink)
    final pinkPaint = Paint()
      ..color = AppColors.accentPink
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.58, h * 0.52), w * 0.09, pinkPaint);

    // Botanical Leaves at top-right
    final leafPaint = Paint()
      ..color = AppColors.leafGreen
      ..style = PaintingStyle.fill;

    final leafPath = Path();
    leafPath.moveTo(w * 0.72, h * 0.16);
    leafPath.quadraticBezierTo(w * 0.85, h * 0.05, w * 0.92, h * 0.15);
    leafPath.quadraticBezierTo(w * 0.82, h * 0.24, w * 0.72, h * 0.16);
    canvas.drawPath(leafPath, leafPaint);

    final leafPath2 = Path();
    leafPath2.moveTo(w * 0.82, h * 0.22);
    leafPath2.quadraticBezierTo(w * 0.95, h * 0.18, w * 0.96, h * 0.3);
    leafPath2.quadraticBezierTo(w * 0.86, h * 0.32, w * 0.82, h * 0.22);
    canvas.drawPath(leafPath2, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
