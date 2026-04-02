import 'dart:math';
import 'package:flutter/material.dart';

/// La Verda Stelo — símbolo oficial del Esperanto
class EsperantoStar extends StatelessWidget {
  final double size;
  final Color color;

  const EsperantoStar({
    super.key,
    this.size = 32,
    this.color = const Color(0xFF22C55E),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _StarPainter(color: color),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color color;
  _StarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    // 5-pointed star: outer radius & inner radius
    final outerR = size.width / 2;
    final innerR = outerR * 0.382; // golden ratio inner point
    const points = 5;
    const startAngle = -pi / 2; // top point

    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = startAngle + (i * pi / points);
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}
