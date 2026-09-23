/// A body posture shown in the prayer guide animation.
///
/// Names match the keys used in `assets/files/prayer_guide/prayer_guide.json`.
enum PrayerPosture {
  /// Standing still, arms at the sides.
  standing,

  /// Hands raised for the opening takbir.
  takbir,

  /// Standing with the right hand over the left forearm (recitation).
  qiyam,

  /// Bowing with a level back, hands on the knees.
  ruku,

  /// Standing upright again after the bow.
  itidal,

  /// Transitional kneel between standing and prostration.
  kneel,

  /// Prostration on the seven bones.
  sujud,

  /// Sitting between the prostrations (iftirash).
  sitting,

  /// Sitting for the tashahhud with the index finger raised.
  tashahhud,

  /// Head turned to the right for the first salam.
  tasleemRight,

  /// Head turned to the left for the second salam.
  tasleemLeft,
}
