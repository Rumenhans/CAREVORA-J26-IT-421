import 'package:flutter/material.dart';

class WaveDivider extends StatelessWidget {
  final Color color;
  final double height;
  final bool isReversed;

  const WaveDivider({
    super.key,
    required this.color,
    this.height = 40,
    this.isReversed = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _WavePainter(color: color, isReversed: isReversed),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;
  final bool isReversed;

  _WavePainter({required this.color, required this.isReversed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isReversed) {
      path.moveTo(0, size.height);
      path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, size.height * 0.5);
      path.quadraticBezierTo(size.width * 0.75, size.height, size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, 0);
      path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height * 0.5);
      path.quadraticBezierTo(size.width * 0.75, 0, size.width, size.height);
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isReversed != isReversed;
}
