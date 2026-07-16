import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A misbaha: a ring of gold beads that rotates one bead per press, a fixed
/// gold finial (the "imam" head-piece) above the ring, and the fixed centre
/// text. Only the bead ring rotates — the finial and centre text never move,
/// so it reads like pulling beads past a stationary head.
class TasbehBeads extends StatelessWidget {
  final int totalCount;
  final String dhikr;
  final int count;
  final double ringSize;

  static const int beadCount = 33;

  const TasbehBeads({
    super.key,
    required this.totalCount,
    required this.dhikr,
    required this.count,
    this.ringSize = 264,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Room above the ring for the finial.
    final topSpace = ringSize * 0.17;

    // Monotonic: totalCount only ever grows (it does not reset at 33), so the
    // ring advances exactly one bead-step per press and never snaps backwards.
    final turns = totalCount / beadCount;

    return SizedBox(
      width: ringSize,
      height: ringSize + topSpace,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // The bead ring — the only element that rotates.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: ringSize,
            child: AnimatedRotation(
              turns: turns,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              child: CustomPaint(
                size: Size(ringSize, ringSize),
                painter: _BeadRingPainter(),
              ),
            ),
          ),
          // Fixed centre text, centred inside the ring.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: ringSize,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dhikr,
                    style: theme.textTheme.titleLarge!
                        .copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$count',
                    style: theme.textTheme.headlineLarge!
                        .copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ),
          ),
          // Fixed gold finial above the ring.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: CustomPaint(
                size: Size(ringSize * 0.22, topSpace + ringSize * 0.055),
                painter: _FinialPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BeadRingPainter extends CustomPainter {
  // Highlight (top-left) → base gold → deep gold (bottom-right) for the 3-D look.
  static final Color _highlight = Color.lerp(
    AppColors.primaryColor,
    AppColors.white,
    0.55,
  )!;
  static final Color _deep = Color.lerp(
    AppColors.primaryColor,
    AppColors.backgroundColor,
    0.5,
  )!;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const n = TasbehBeads.beadCount;
    final sinHalf = sin(pi / n);

    // Size the beads from the circumference so neighbours touch (a hair of
    // overlap, so there are no visible gaps), and still fit inside the box.
    final ringRadius = (size.width / 2 - 2) / (1 + 1.06 * sinHalf);
    final beadRadius = ringRadius * sinHalf * 1.06;

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = beadRadius * 0.12
      ..color = _deep.withValues(alpha: 0.35);

    for (var i = 0; i < n; i++) {
      final angle = (2 * pi / n) * i - pi / 2;
      final beadCenter = Offset(
        center.dx + ringRadius * cos(angle),
        center.dy + ringRadius * sin(angle),
      );
      final rect = Rect.fromCircle(center: beadCenter, radius: beadRadius);
      final fill = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          radius: 0.95,
          colors: [_highlight, AppColors.primaryColor, _deep],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect);
      canvas.drawCircle(beadCenter, beadRadius, fill);
      // Thin rim so touching beads still read as separate.
      canvas.drawCircle(beadCenter, beadRadius, rim);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The gold head-piece above the ring: a tulip/bulb body pointing down toward
/// the beads, with three short prongs on top. Drawn, not an asset.
class _FinialPainter extends CustomPainter {
  static final Color _highlight = Color.lerp(
    AppColors.primaryColor,
    AppColors.white,
    0.5,
  )!;
  static final Color _deep = Color.lerp(
    AppColors.primaryColor,
    AppColors.backgroundColor,
    0.45,
  )!;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final tipY = h; // bottom point, aimed at the top bead
    final topY = h * 0.34; // where the bulb meets the prongs
    final halfW = w * 0.36;

    final gold = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_highlight, AppColors.primaryColor, _deep],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Three prongs on top (middle taller).
    final prong = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.07
      ..shader = gold.shader;
    canvas.drawLine(Offset(cx, topY), Offset(cx, h * 0.02), prong);
    canvas.drawLine(
        Offset(cx - w * 0.2, topY), Offset(cx - w * 0.2, h * 0.12), prong);
    canvas.drawLine(
        Offset(cx + w * 0.2, topY), Offset(cx + w * 0.2, h * 0.12), prong);

    // Tulip/bulb body tapering to a downward tip.
    final body = Path()
      ..moveTo(cx, tipY)
      ..cubicTo(cx - halfW * 1.15, tipY - h * 0.22, cx - halfW, topY + h * 0.14,
          cx - halfW * 0.55, topY)
      ..quadraticBezierTo(cx, topY - h * 0.08, cx + halfW * 0.55, topY)
      ..cubicTo(cx + halfW, topY + h * 0.14, cx + halfW * 1.15, tipY - h * 0.22,
          cx, tipY)
      ..close();
    canvas.drawPath(body, gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
