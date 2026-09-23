import '../../domain/entities/prayer_posture.dart';
import 'pose.dart';

/// The key-frame pose for each [PrayerPosture].
///
/// Tuned against the proportions in `FigureSkeleton` so that hands land on
/// the knees in ruku, on the ground beside the head in sujud, and on the
/// thighs when sitting.
abstract class PosturePoses {
  static const Pose _standing = Pose(
    torso: 90, head: 90, upperArm: -92, foreArm: -88,
    thigh: -90, shin: -90, foot: 0,
  );

  static const Pose _sitting = Pose(
    torso: 90, head: 90, upperArm: -84, foreArm: -20,
    thigh: -3, shin: 181, foot: -95,
  );

  static Pose of(PrayerPosture posture) => switch (posture) {
    PrayerPosture.standing || PrayerPosture.itidal => _standing,
    PrayerPosture.takbir => const Pose(
      torso: 90, head: 90, upperArm: -35, foreArm: 100,
      thigh: -90, shin: -90, foot: 0,
    ),
    PrayerPosture.qiyam => const Pose(
      torso: 90, head: 88, upperArm: -100, foreArm: 40,
      thigh: -90, shin: -90, foot: 0,
    ),
    PrayerPosture.ruku => const Pose(
      torso: 0, head: -8, upperArm: -128, foreArm: -134,
      thigh: -76, shin: -101, foot: 0,
    ),
    PrayerPosture.kneel => const Pose(
      torso: 62, head: 45, upperArm: -60, foreArm: -62,
      thigh: -40, shin: 182, foot: -80,
    ),
    PrayerPosture.sujud => const Pose(
      torso: -20, head: -45, upperArm: -143, foreArm: -46,
      thigh: -62, shin: 164, foot: -80, armScale: 0.65,
    ),
    PrayerPosture.sitting => _sitting,
    PrayerPosture.tashahhud => _sitting.copyWith(fingerRaise: 1),
    PrayerPosture.tasleemRight => _sitting.copyWith(headTurn: 1),
    PrayerPosture.tasleemLeft => _sitting.copyWith(headTurn: -1),
  };
}
