import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A centred "nothing to show" line — no data at all, or nothing left after a
/// search. Failures use [ErrorView] instead, which can also offer a retry.
class EmptyMessage extends StatelessWidget {
  final String message;

  final EdgeInsetsGeometry padding;

  /// Cream by default; the hints that read as a call to action are gold.
  final Color color;

  /// Uses the smaller body style.
  final bool dense;

  const EmptyMessage({
    super.key,
    required this.message,
    this.padding = EdgeInsets.zero,
    this.color = AppColors.textColor,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: (dense ? theme.textTheme.bodyMedium! : theme.textTheme.bodyLarge!)
              .copyWith(color: color),
        ),
      ),
    );
  }
}
