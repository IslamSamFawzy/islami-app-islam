import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/prayer_guide.dart';

/// A quoted hadith with its reference, framed with a gold side rule.
class HadithEvidenceCard extends StatelessWidget {
  final HadithEvidence evidence;

  /// The intro hadith is shown larger than the per-step evidence.
  final bool emphasized;

  const HadithEvidenceCard({
    super.key,
    required this.evidence,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final quoteStyle = (emphasized ? textTheme.headlineSmall : textTheme.bodyLarge)!
        .copyWith(color: AppColors.primaryColor, height: 1.9);

    // A rounded box can't take a one-sided border, so the gold rule is its
    // own strip inside a clipped row (start side = right in RTL).
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        child: IntrinsicHeight(
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                width: 3,
                child: ColoredBox(color: AppColors.primaryColor),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '«${evidence.text}»',
                        textAlign:
                            emphasized ? TextAlign.center : TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: quoteStyle,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        evidence.source,
                        textAlign:
                            emphasized ? TextAlign.center : TextAlign.left,
                        textDirection: TextDirection.rtl,
                        style: textTheme.bodyMedium!.copyWith(
                          color: AppColors.textColor.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
