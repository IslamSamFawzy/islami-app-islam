import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The app's search field styling in one place (dark fill @70%, 1px gold
/// border, radius 12, gold prefix icon, cream hint), generalised to an
/// [onChanged] + [hintText] so it can be reused without dragging any bloc along.
///
/// Pass a [controller] when the text must be cleared externally (e.g. the Radio
/// tab clears the query when you switch tabs).
class SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hintText;
  final TextEditingController? controller;

  /// Overrides the default gold search glyph (e.g. the Quran tab passes its
  /// own icon so its look is unchanged).
  final Widget? prefixIcon;

  const SearchField({
    super.key,
    required this.onChanged,
    required this.hintText,
    this.controller,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      style: Theme.of(context)
          .textTheme
          .bodyLarge!
          .copyWith(color: AppColors.textColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textColor,
        ),
        filled: true,
        fillColor: AppColors.backgroundColor.withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(width: 1, color: AppColors.primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(width: 1, color: AppColors.primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(width: 1, color: AppColors.primaryColor),
        ),
        prefixIcon: prefixIcon ??
            const Icon(Icons.search, color: AppColors.primaryColor),
      ),
    );
  }
}
