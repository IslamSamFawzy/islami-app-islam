import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A centred failure message: the [message] itself, an optional [icon] above it
/// and an optional "Retry" button below.
class ErrorView extends StatelessWidget {
  final String message;

  /// Shown above the message when the failure has a telling icon (Qibla's
  /// location states).
  final IconData? icon;

  /// When non-null, a "Retry" button is shown under the message.
  final VoidCallback? onRetry;

  final EdgeInsetsGeometry padding;

  /// Colour of the icon, message and button. Gold by default; the screens that
  /// show a failure inside otherwise-populated content pass the cream text
  /// colour instead.
  final Color color;

  /// Uses the smaller body style, for a failure shown inside a list rather than
  /// on an empty screen.
  final bool dense;

  const ErrorView({
    super.key,
    required this.message,
    this.icon,
    this.onRetry,
    this.padding = EdgeInsets.zero,
    this.color = AppColors.primaryColor,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = (dense ? theme.textTheme.bodyMedium! : theme.textTheme.bodyLarge!)
        .copyWith(color: color);

    return Padding(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 64),
              const SizedBox(height: 20),
            ],
            Text(message, textAlign: TextAlign.center, style: textStyle),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Retry',
                  style: theme.textTheme.bodyLarge!.copyWith(color: color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
