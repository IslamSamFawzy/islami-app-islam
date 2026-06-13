import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A ring of prayer beads that rotates by one bead each press.
class TasbehBeads extends StatelessWidget {
  final int totalCount;
  final double size;

  static const int beadCount = 33;

  const TasbehBeads({
    super.key,
    required this.totalCount,
    this.size = 240,
  });

  @override
  Widget build(BuildContext context) {
    // Monotonic rotation: one bead-step per press, smoothly animated.
    final turns = totalCount / beadCount;
    return AnimatedRotation(
      turns: turns,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: CustomPaint(
        size: Size(size, size),
        painter: _BeadsPainter(),
      ),
    );
  }
}

class _BeadsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringRadius = size.width / 2 - 18;
    final beadRadius = size.width * 0.055;

    final fill = Paint()..style = PaintingStyle.fill;
    final shade = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.backgroundColor.withValues(alpha: 0.25);

    for (var i = 0; i < TasbehBeads.beadCount; i++) {
      final angle = (2 * pi / TasbehBeads.beadCount) * i - pi / 2;
      final dx = center.dx + ringRadius * cos(angle);
      final dy = center.dy + ringRadius * sin(angle);
      final offset = Offset(dx, dy);

      // The bead at the top (i == 0) is the "active" marker bead.
      fill.color = i == 0
          ? AppColors.textColor
          : AppColors.primaryColor;

      canvas.drawCircle(offset, i == 0 ? beadRadius * 1.25 : beadRadius, fill);
      canvas.drawCircle(
        offset.translate(beadRadius * 0.3, beadRadius * 0.3),
        beadRadius * 0.35,
        shade,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
