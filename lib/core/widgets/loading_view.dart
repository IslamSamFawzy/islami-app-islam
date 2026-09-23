import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The app's single loading indicator: the gold spinner, centred.
///
/// [padding] is for the screens that show it inside a page rather than on an
/// otherwise empty one (the Suras list, the prayer card).
class LoadingView extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const LoadingView({super.key, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      ),
    );
  }
}
