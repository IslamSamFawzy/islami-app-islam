import 'dart:math' as math;
import 'dart:ui';

import 'pose.dart';

/// Joint positions of the figure for a [Pose], in figure units with **y up**.
///
/// The skeleton is grounded: its lowest point (including the stroke
/// thickness) sits on y = 0, and the toe is pinned to x = 0 so the feet stay
/// planted on the mat while the body moves between postures.
class FigureSkeleton {
  static const double headRadius = 7;
  static const double neckLength = 3;
  static const double torsoLength = 28;
  static const double upperArmLength = 15;
  static const double foreArmLength = 14;
  static const double thighLength = 23;
  static const double shinLength = 22;
  static const double footLength = 7;

  /// Half the thickness of the limb strokes — keeps them from sinking into
  /// the ground line.
  static const double groundClearance = 3.5;

  final Offset hip;
  final Offset neck;
  final Offset shoulder;
  final Offset head;
  final Offset elbow;
  final Offset hand;
  final Offset knee;
  final Offset ankle;
  final Offset toe;

  const FigureSkeleton._({
    required this.hip,
    required this.neck,
    required this.shoulder,
    required this.head,
    required this.elbow,
    required this.hand,
    required this.knee,
    required this.ankle,
    required this.toe,
  });

  factory FigureSkeleton.fromPose(Pose p) {
    const hip = Offset.zero;
    final neck = along(hip, p.torso, torsoLength);
    final head = along(neck, p.head, neckLength + headRadius);
    final shoulder = along(neck, p.torso + 180, 3);
    final elbow = along(shoulder, p.upperArm, upperArmLength * p.armScale);
    final hand = along(elbow, p.foreArm, foreArmLength * p.armScale);
    final knee = along(hip, p.thigh, thighLength);
    final ankle = along(knee, p.shin, shinLength);
    final toe = along(ankle, p.foot, footLength);

    final lowestJoint = [hip, neck, shoulder, elbow, hand, knee, ankle, toe]
        .map((o) => o.dy)
        .reduce(math.min);
    final minY = math.min(lowestJoint - groundClearance, head.dy - headRadius);
    final shift = Offset(-toe.dx, -minY);

    return FigureSkeleton._(
      hip: hip + shift,
      neck: neck + shift,
      shoulder: shoulder + shift,
      head: head + shift,
      elbow: elbow + shift,
      hand: hand + shift,
      knee: knee + shift,
      ankle: ankle + shift,
      toe: toe + shift,
    );
  }

  /// The same skeleton moved by [offset] (used to draw the far-side limbs).
  FigureSkeleton translate(Offset offset) => FigureSkeleton._(
    hip: hip + offset,
    neck: neck + offset,
    shoulder: shoulder + offset,
    head: head + offset,
    elbow: elbow + offset,
    hand: hand + offset,
    knee: knee + offset,
    ankle: ankle + offset,
    toe: toe + offset,
  );

  List<Offset> get joints =>
      [hip, neck, shoulder, head, elbow, hand, knee, ankle, toe];

  /// The point [length] units from [from] in direction [degrees] (y up).
  static Offset along(Offset from, double degrees, double length) {
    final r = degrees * math.pi / 180;
    return from + Offset(math.cos(r) * length, math.sin(r) * length);
  }
}
