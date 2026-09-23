import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/prayer_guide.dart';
import 'figure_stage.dart';
import 'hadith_evidence_card.dart';

/// First page: a full rak'ah on loop, the hadith that tells us why we pray
/// this way, and how many rak'at each prayer has.
class PrayerOverviewPage extends StatelessWidget {
  final PrayerGuide guide;

  const PrayerOverviewPage({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          FigureStage(
            postures: guide.overviewPostures,
            semanticsLabel: 'ركعة كاملة',
          ),
          const SizedBox(height: 18),
          Text(
            guide.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall!.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 14),
          HadithEvidenceCard(evidence: guide.introHadith, emphasized: true),
          const SizedBox(height: 14),
          Text(
            guide.introText,
            style: textTheme.bodyLarge!.copyWith(
              color: AppColors.textColor,
              height: 1.8,
            ),
          ),
          if (guide.rakaat.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'عدد الركعات',
              style: textTheme.titleLarge!.copyWith(color: AppColors.textColor),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in guide.rakaat) _RakaatChip(rakaat: r),
              ],
            ),
          ],
          if (guide.note.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              guide.note,
              style: textTheme.bodyMedium!.copyWith(
                color: AppColors.textColor.withValues(alpha: 0.7),
                height: 1.7,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'اسحب لليسار لتبدأ الخطوات ←',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium!.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RakaatChip extends StatelessWidget {
  final RakaatCount rakaat;

  const _RakaatChip({required this.rakaat});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryColor),
      ),
      child: Text(
        '${rakaat.prayer}: ${rakaat.count}',
        style: textTheme.bodyLarge!.copyWith(color: AppColors.textColor),
      ),
    );
  }
}
