import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/prayer_guide.dart';
import 'figure_stage.dart';
import 'hadith_evidence_card.dart';
import 'recitation_box.dart';

/// One step: the animation, what to do, what to say, and the hadith behind it.
class PrayerStepPage extends StatelessWidget {
  final PrayerStep step;

  /// 1-based step number.
  final int number;

  const PrayerStepPage({super.key, required this.step, required this.number});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          FigureStage(postures: step.postures, semanticsLabel: step.title),
          const SizedBox(height: 18),
          Text(
            'الخطوة $number',
            style: textTheme.bodyMedium!.copyWith(
              color: AppColors.textColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            step.title,
            style: textTheme.headlineSmall!.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            step.description,
            style: textTheme.bodyLarge!.copyWith(
              color: AppColors.textColor,
              height: 1.8,
            ),
          ),
          if (step.recitation.isNotEmpty) ...[
            const SizedBox(height: 16),
            RecitationBox(text: step.recitation),
          ],
          if (step.evidence.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'الدليل من السنة',
              style: textTheme.titleLarge!.copyWith(
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 10),
            for (final e in step.evidence) ...[
              HadithEvidenceCard(evidence: e),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}
