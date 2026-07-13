import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Waveform inside radio/reciter tiles. The bars animate as a travelling wave
/// while [active] (playing); otherwise they sit still and dimmed (spec §2.7).
class Waveform extends StatefulWidget {
  final bool active;

  const Waveform({super.key, this.active = false});

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant Waveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _WaveformPainter(
            active: widget.active,
            phase: _controller.value,
          ),
          size: const Size(double.infinity, 36),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final bool active;
  final double phase;

  _WaveformPainter({required this.active, required this.phase});

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
    final midY = size.height / 2;
    final maxH = size.height - 6;
    final rnd = Random(42);

    for (var i = 0; i < count; i++) {
      final x = i * barGap + 1;
      final double h;
      if (active) {
        // Each bar is phase-shifted from its neighbour → a travelling wave.
        final t = phase * 2 * pi + i * 0.55;
        h = 4 + (0.5 + 0.5 * sin(t)) * maxH;
      } else {
        // Deterministic static silhouette when idle.
        h = 4 + rnd.nextDouble() * maxH;
      }
      canvas.drawLine(
        Offset(x, midY - h / 2),
        Offset(x, midY + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.active != active || oldDelegate.phase != phase;
}
