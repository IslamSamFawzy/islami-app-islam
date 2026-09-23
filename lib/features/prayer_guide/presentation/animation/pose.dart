import 'dart:ui' show lerpDouble;

import 'package:equatable/equatable.dart';

/// A figure pose in side view (facing right, towards the Qibla).
///
/// Every angle is the **absolute** direction, in degrees, of a body segment
/// going from its parent joint to its child joint: 0° points forward (screen
/// right), 90° points up, -90° points down. Only the near-side limbs are
/// described; the far-side limbs mirror them.
class Pose extends Equatable {
  /// Hip → neck.
  final double torso;

  /// Neck → head centre.
  final double head;

  /// Shoulder → elbow.
  final double upperArm;

  /// Elbow → hand.
  final double foreArm;

  /// Hip → knee.
  final double thigh;

  /// Knee → ankle.
  final double shin;

  /// Ankle → toe.
  final double foot;

  /// Shortens the arms to fake foreshortening when they point sideways
  /// (e.g. the elbows spread out in sujud). 1 = full length.
  final double armScale;

  /// 0..1 — how far the index finger is raised (tashahhud).
  final double fingerRaise;

  /// -1 (looking left) .. 0 .. 1 (looking right) — the salam.
  final double headTurn;

  const Pose({
    required this.torso,
    required this.head,
    required this.upperArm,
    required this.foreArm,
    required this.thigh,
    required this.shin,
    required this.foot,
    this.armScale = 1,
    this.fingerRaise = 0,
    this.headTurn = 0,
  });

  Pose copyWith({double? fingerRaise, double? headTurn}) => Pose(
    torso: torso,
    head: head,
    upperArm: upperArm,
    foreArm: foreArm,
    thigh: thigh,
    shin: shin,
    foot: foot,
    armScale: armScale,
    fingerRaise: fingerRaise ?? this.fingerRaise,
    headTurn: headTurn ?? this.headTurn,
  );

  /// Interpolates every angle along the shortest arc, so a limb never spins
  /// the long way round.
  static Pose lerp(Pose a, Pose b, double t) => Pose(
    torso: lerpAngle(a.torso, b.torso, t),
    head: lerpAngle(a.head, b.head, t),
    upperArm: lerpAngle(a.upperArm, b.upperArm, t),
    foreArm: lerpAngle(a.foreArm, b.foreArm, t),
    thigh: lerpAngle(a.thigh, b.thigh, t),
    shin: lerpAngle(a.shin, b.shin, t),
    foot: lerpAngle(a.foot, b.foot, t),
    armScale: lerpDouble(a.armScale, b.armScale, t)!,
    fingerRaise: lerpDouble(a.fingerRaise, b.fingerRaise, t)!,
    headTurn: lerpDouble(a.headTurn, b.headTurn, t)!,
  );

  /// Shortest-path interpolation between two angles in degrees.
  static double lerpAngle(double a, double b, double t) {
    final diff = ((b - a + 540) % 360) - 180;
    return a + diff * t;
  }

  @override
  List<Object?> get props => [
    torso,
    head,
    upperArm,
    foreArm,
    thigh,
    shin,
    foot,
    armScale,
    fingerRaise,
    headTurn,
  ];
}
