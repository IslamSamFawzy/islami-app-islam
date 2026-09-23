import 'dart:ui';

abstract class AppColors {
  static const Color backgroundColor = Color (0xff202020);
  static const Color primaryColor = Color (0xffE2BE7F);
  static const Color textColor = Color (0xffFEFFE8);
  static const Color titleTextColor = Color(0xff202020);
  static const Color white = Color(0xffFFFFFF);

  /// Dark card gradient, top to bottom (the Azkar and Qibla entry cards).
  static const Color cardGradientTop = Color(0xff262019);
  static const Color cardGradientBottom = Color(0xff0A0806);

  /// Prayer pills on the Pray Time card: the centred one gets a three-stop
  /// gradient with a lit top, the side ones a flatter two-stop.
  static const Color pillSelectedTop = Color(0xff5A4F3D);
  static const Color pillSelectedMiddle = Color(0xff262019);
  static const Color pillSelectedBottom = Color(0xff060504);
  static const Color pillTop = Color(0xff2A2218);
  static const Color pillBottom = Color(0xff0A0805);
}