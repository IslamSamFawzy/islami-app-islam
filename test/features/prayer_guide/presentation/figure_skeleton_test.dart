import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/prayer_guide/domain/entities/prayer_posture.dart';
import 'package:islami/features/prayer_guide/presentation/animation/figure_skeleton.dart';
import 'package:islami/features/prayer_guide/presentation/animation/pose.dart';
import 'package:islami/features/prayer_guide/presentation/animation/posture_poses.dart';

void main() {
  void expectGroundedAndInView(Pose pose, String label) {
    final s = FigureSkeleton.fromPose(pose);
    // Toe pinned to x = 0 so the feet stay planted between postures.
    expect(s.toe.dx, closeTo(0, 1e-9), reason: label);
    // Nothing below the ground line.
    for (final j in s.joints) {
      expect(j.dy, greaterThanOrEqualTo(-1e-9), reason: label);
    }
    // Everything inside the painter's window (x -22..60, y up to 100),
    // allowing for the head radius and the far-side offset.
    for (final j in s.joints) {
      expect(j.dx, inInclusiveRange(-20, 53), reason: label);
      expect(j.dy, lessThanOrEqualTo(92), reason: label);
    }
  }

  test('every posture is grounded and fits the view', () {
    for (final p in PrayerPosture.values) {
      expectGroundedAndInView(PosturePoses.of(p), p.name);
    }
  });

  test('every blend between two postures stays grounded and in view', () {
    for (final a in PrayerPosture.values) {
      for (final b in PrayerPosture.values) {
        for (var i = 0; i <= 10; i++) {
          final pose = Pose.lerp(PosturePoses.of(a), PosturePoses.of(b), i / 10);
          expectGroundedAndInView(pose, '${a.name}->${b.name}@$i');
        }
      }
    }
  });

  test('angles interpolate along the shortest arc', () {
    expect(Pose.lerpAngle(170, -170, 0.5), closeTo(180, 1e-9));
    expect(Pose.lerpAngle(-90, 0, 0.5), closeTo(-45, 1e-9));
    expect(Pose.lerpAngle(10, 350, 1), closeTo(-10, 1e-9));
  });

  test('lerp endpoints return the original poses', () {
    final a = PosturePoses.of(PrayerPosture.qiyam);
    final b = PosturePoses.of(PrayerPosture.ruku);
    expect(Pose.lerp(a, b, 0), a);
    final end = Pose.lerp(a, b, 1);
    expect(end.torso, closeTo(b.torso, 1e-9));
    expect(end.foreArm % 360, closeTo(b.foreArm % 360, 1e-9));
  });

  test('head reaches the ground in sujud', () {
    final s = FigureSkeleton.fromPose(PosturePoses.of(PrayerPosture.sujud));
    expect(s.head.dy - FigureSkeleton.headRadius, lessThan(1.5));
  });
}
