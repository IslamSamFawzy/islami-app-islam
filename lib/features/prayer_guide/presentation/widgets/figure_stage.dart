import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/prayer_posture.dart';
import 'animated_prayer_figure.dart';

/// The framed "stage" the animated figure performs on.
class FigureStage extends StatelessWidget {
  final List<PrayerPosture> postures;
  final String semanticsLabel;
  final double height;

  const FigureStage({
    super.key,
    required this.postures,
    required this.semanticsLabel,
    this.height = 230,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryColor),
      ),
      child: AnimatedPrayerFigure(
        postures: postures,
        semanticsLabel: semanticsLabel,
      ),
    );
  }
}
