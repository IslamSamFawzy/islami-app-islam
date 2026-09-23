import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Solid gold box with what the worshipper says in this step.
class RecitationBox extends StatelessWidget {
  final String text;

  const RecitationBox({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ماذا تقول',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: textTheme.bodyMedium!.copyWith(
              color: AppColors.titleTextColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge!.copyWith(
              color: AppColors.titleTextColor,
              height: 1.9,
            ),
          ),
        ],
      ),
    );
  }
}
