import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The circular Qibla dial: a gold ring with degree ticks and N/E/S/W letters
/// that counter-rotates with the device heading (so N tracks true north), and
/// a gold Kaaba needle that points at the Qibla. Everything is drawn with
/// [CustomPainter] — no image assets.
class QiblaCompass extends StatelessWidget {
  /// Device heading in the true-north frame (`0..360`), or `null` before the
  /// first reading (dial then rests with N up).
  final double? heading;

  /// Qibla bearing from true north (`0..360`).
  final double qiblaBearing;

  /// Highlights the needle when the device is on the Qibla.
  final bool isAligned;

  const QiblaCompass({
    super.key,
    required this.heading,
    required this.qiblaBearing,
    required this.isAligned,
  });

  @override
  Widget build(BuildContext context) {
    final h = heading ?? 0;
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ring + ticks + letters: counter-rotate so N points at true north.
          _SmoothRotation(
            angleDeg: -h,
            child: CustomPaint(
              size: Size.infinite,
              painter: _DialPainter(),
            ),
          ),
          // Needle: points at (qibla − heading) on screen.
          _SmoothRotation(
            angleDeg: qiblaBearing - h,
            child: CustomPaint(
              size: Size.infinite,
              painter: _NeedlePainter(isAligned: isAligned),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rotates [child] to [angleDeg] (degrees clockwise) along the **shortest**
/// path, so the needle never spins the long way round when crossing 0°/360°.
class _SmoothRotation extends StatefulWidget {
  final double angleDeg;
  final Widget child;

  const _SmoothRotation({
    required this.angleDeg,
    required this.child,
  });

  @override
  State<_SmoothRotation> createState() => _SmoothRotationState();
}

class _SmoothRotationState extends State<_SmoothRotation> {
  // Accumulated turns fed to AnimatedRotation. Unwrapped so successive targets
  // always take the short way (|delta| <= half a turn).
  late double _turns = widget.angleDeg / 360.0;

  @override
  void didUpdateWidget(covariant _SmoothRotation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.angleDeg != widget.angleDeg) {
      final current = _turns * 360.0;
      var delta = (widget.angleDeg - current) % 360.0;
      if (delta > 180) delta -= 360;
      _turns += delta / 360.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: _turns,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: widget.child,
    );
  }
}

class _DialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.primaryColor;

    // Outer ring + a faint inner ring for depth.
    canvas.drawCircle(center, radius - 1, ring);
    canvas.drawCircle(
      center,
      radius * 0.80,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.primaryColor.withValues(alpha: 0.25),
    );

    // Degree ticks: long every 30°, short every 10°.
    for (var deg = 0; deg < 360; deg += 10) {
      final isMajor = deg % 30 == 0;
      final rad = deg * math.pi / 180.0;
      final dir = Offset(math.sin(rad), -math.cos(rad));
      final outer = center + dir * (radius - 2);
      final inner = center + dir * (radius - (isMajor ? 16 : 9));
      canvas.drawLine(
        outer,
        inner,
        Paint()
          ..strokeWidth = isMajor ? 2 : 1
          ..color = AppColors.primaryColor
              .withValues(alpha: isMajor ? 0.95 : 0.55),
      );
    }

    // Cardinal letters, attached to the dial so they track their direction.
    const labels = {0: 'N', 90: 'E', 180: 'S', 270: 'W'};
    labels.forEach((deg, letter) {
      final rad = deg * math.pi / 180.0;
      final dir = Offset(math.sin(rad), -math.cos(rad));
      final pos = center + dir * (radius - 34);
      final tp = TextPainter(
        text: TextSpan(
          text: letter,
          style: TextStyle(
            fontFamily: 'Janna',
            fontSize: letter == 'N' ? 22 : 18,
            fontWeight: FontWeight.w700,
            // North stands out from the other three.
            color: letter == 'N'
                ? AppColors.primaryColor
                : AppColors.primaryColor.withValues(alpha: 0.75),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    });
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) => false;
}

class _NeedlePainter extends CustomPainter {
  final bool isAligned;

  _NeedlePainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final tipY = center.dy - radius * 0.62; // arrow tip near the ring
    final halfWidth = radius * 0.055;

    final gold = isAligned
        ? Color.lerp(AppColors.primaryColor, AppColors.white, 0.45)!
        : AppColors.primaryColor;

    // Soft glow behind the needle when aligned.
    if (isAligned) {
      final glow = Paint()
        ..color = AppColors.primaryColor.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawLine(
        Offset(center.dx, tipY),
        center,
        glow..strokeWidth = halfWidth * 3,
      );
    }

    // Muted tail pointing away from the Qibla.
    canvas.drawLine(
      center,
      Offset(center.dx, center.dy + radius * 0.5),
      Paint()
        ..strokeWidth = 2
        ..color = AppColors.primaryColor.withValues(alpha: 0.35),
    );

    // The gold arrow toward the Qibla.
    final arrow = Path()
      ..moveTo(center.dx, tipY)
      ..lineTo(center.dx - halfWidth, center.dy)
      ..lineTo(center.dx + halfWidth, center.dy)
      ..close();
    canvas.drawPath(arrow, Paint()..color = gold);

    // A small Kaaba cube at the tip (no asset — drawn).
    _drawKaaba(canvas, Offset(center.dx, tipY - radius * 0.06), radius * 0.11,
        gold);

    // Centre hub.
    canvas.drawCircle(center, halfWidth * 1.3, Paint()..color = gold);
    canvas.drawCircle(
      center,
      halfWidth * 1.3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.backgroundColor,
    );
  }

  void _drawKaaba(Canvas canvas, Offset c, double s, Color gold) {
    final rect = Rect.fromCenter(center: c, width: s, height: s);
    // Cube body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()..color = gold,
    );
    // Kiswa band across the top third, in the dark background colour.
    final band = Rect.fromLTWH(
      rect.left,
      rect.top + s * 0.28,
      s,
      s * 0.16,
    );
    canvas.drawRect(band, Paint()..color = AppColors.backgroundColor);
  }

  @override
  bool shouldRepaint(covariant _NeedlePainter oldDelegate) =>
      oldDelegate.isAligned != isAligned;
}
