import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Shown when a tab has no data at all.
class RadioEmptyHint extends StatelessWidget {
  final String text;

  const RadioEmptyHint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: const TextStyle(color: AppColors.primaryColor)),
    );
  }
}

/// Shown when a search filters everything out (there is data, just no match).
class RadioNoResults extends StatelessWidget {
  const RadioNoResults({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No results',
        style: Theme.of(context)
            .textTheme
            .bodyLarge!
            .copyWith(color: AppColors.textColor),
      ),
    );
  }
}
