import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../animation/figure_skeleton.dart';
import '../animation/pose.dart';

/// Paints a faceless, side-view figure in [pose] standing on a prayer mat.
///
/// The figure faces right (the Qibla). Far-side limbs are drawn first in a
/// dimmer shade so the silhouette reads as a body rather than a stick figure.
class PrayerFigurePainter extends CustomPainter {
  final Pose pose;
  final Color color;
  final Color farColor;
  final Color matColor;

  /// Labels drawn above the head while the salam head-turn is shown.
  final String rightLabel;
  final String leftLabel;
  final TextStyle labelStyle;

  PrayerFigurePainter({
    required this.pose,
    required this.color,
    required this.farColor,
    required this.matColor,
    required this.labelStyle,
    this.rightLabel = 'يمينًا',
    this.leftLabel = 'يسارًا',
  });

  // The figure-space window every pose (and every blend between poses) fits
  // in: x from _left to _right, y from _bottom to _top (y up).
  static const double _left = -22;
  static const double _right = 60;
  static const double _bottom = -5;
  static const double _top = 100;

  // Stroke thickness of each segment, in figure units.
  static const double _torsoWidth = 13;
  static const double _thighWidth = 9;
  static const double _shinWidth = 7.5;
  static const double _footWidth = 6;
  static const double _upperArmWidth = 6.5;
  static const double _foreArmWidth = 6;

  /// Where the far-side limbs sit relative to the near ones.
  static const Offset _farSide = Offset(-1.8, 0);

  @override
  void paint(Canvas canvas, Size size) {
    const viewWidth = _right - _left;
    const viewHeight = _top - _bottom;
    final scale = math.min(size.width / viewWidth, size.height / viewHeight);
    final dx = (size.width - viewWidth * scale) / 2;
    final dy = (size.height - viewHeight * scale) / 2;

    Offset toScreen(Offset p) =>
        Offset(dx + (p.dx - _left) * scale, dy + (_top - p.dy) * scale);

    void segment(Offset a, Offset b, double width, Color c) {
      canvas.drawLine(
        toScreen(a),
        toScreen(b),
        Paint()
          ..color = c
          ..strokeWidth = width * scale
          ..strokeCap = StrokeCap.round,
      );
    }

    _paintMat(canvas, toScreen, scale);

    final near = FigureSkeleton.fromPose(pose);
    final far = near.translate(_farSide);

    // Far leg + far arm, behind the body.
    segment(far.hip, far.knee, _thighWidth, farColor);
    segment(far.knee, far.ankle, _shinWidth, farColor);
    segment(far.ankle, far.toe, _footWidth, farColor);
    segment(far.shoulder, far.elbow, _upperArmWidth, farColor);
    segment(far.elbow, far.hand, _foreArmWidth, farColor);

    // Body, near leg and head.
    segment(near.hip, near.neck, _torsoWidth, color);
    segment(near.hip, near.knee, _thighWidth, color);
    segment(near.knee, near.ankle, _shinWidth, color);
    segment(near.ankle, near.toe, _footWidth, color);
    canvas.drawCircle(
      toScreen(near.head),
      FigureSkeleton.headRadius * scale,
      Paint()..color = color,
    );

    // Near arm last so it reads in front of the torso.
    segment(near.shoulder, near.elbow, _upperArmWidth, color);
    segment(near.elbow, near.hand, _foreArmWidth, color);

    if (pose.fingerRaise > 0.01) {
      final tip = FigureSkeleton.along(near.hand, 70, 6 * pose.fingerRaise);
      segment(near.hand, tip, 2.4, color);
    }

    if (pose.headTurn.abs() > 0.05) {
      _paintHeadTurn(canvas, toScreen(near.head), scale);
    }
  }

  void _paintMat(Canvas canvas, Offset Function(Offset) toScreen, double scale) {
    final rect = Rect.fromPoints(
      toScreen(const Offset(-20, 0)),
      toScreen(const Offset(58, -3)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(1.5 * scale)),
      Paint()..color = matColor,
    );
    // A small chevron at the front edge: the direction of the Qibla.
    final tip = toScreen(const Offset(58, 4));
    final chevron = Path()
      ..moveTo(tip.dx - 3 * scale, tip.dy - 2.5 * scale)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - 3 * scale, tip.dy + 2.5 * scale);
    canvas.drawPath(
      chevron,
      Paint()
        ..color = matColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintHeadTurn(Canvas canvas, Offset head, double scale) {
    final opacity = pose.headTurn.abs().clamp(0.0, 1.0);
    final painter = TextPainter(
      text: TextSpan(
        text: pose.headTurn > 0 ? rightLabel : leftLabel,
        style: labelStyle.copyWith(
          color: (labelStyle.color ?? color).withValues(alpha: opacity),
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    painter.paint(
      canvas,
      head -
          Offset(
            painter.width / 2,
            FigureSkeleton.headRadius * scale + painter.height + 4,
          ),
    );
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant PrayerFigurePainter oldDelegate) =>
      oldDelegate.pose != pose ||
      oldDelegate.color != color ||
      oldDelegate.farColor != farColor ||
      oldDelegate.matColor != matColor ||
      oldDelegate.labelStyle != labelStyle;
}
