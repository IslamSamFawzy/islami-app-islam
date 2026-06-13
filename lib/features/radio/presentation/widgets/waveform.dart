import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Decorative static waveform used inside radio/reciter tiles.
class Waveform extends StatelessWidget {
  final bool active;

  const Waveform({super.key, this.active = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: CustomPaint(
        painter: _WaveformPainter(active: active),
        size: const Size(double.infinity, 36),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final bool active;

  _WaveformPainter({required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = active
          ? AppColors.backgroundColor
          : AppColors.backgroundColor.withValues(alpha: 0.55)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    const barGap = 5.0;
    final count = (size.width / barGap).floor();
    final rnd = Random(42);
    final midY = size.height / 2;

    for (var i = 0; i < count; i++) {
      final x = i * barGap + 1;
      final h = 4 + rnd.nextDouble() * (size.height - 6);
      canvas.drawLine(
        Offset(x, midY - h / 2),
        Offset(x, midY + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.active != active;
}
