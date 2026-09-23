import 'package:flutter/material.dart';

import '../gen/assets.gen.dart';
import '../theme/app_colors.dart';

/// A screen's full-bleed background image, plus the app's transparent AppBar
/// with its gold title when the screen has one.
///
/// Every screen used to repeat this: a Container with a DecorationImage, a
/// transparent Scaffold, and an AppBar configured the same way each time.
class AppBackground extends StatelessWidget {
  /// The backdrop drawn behind everything.
  final AssetGenImage image;

  /// AppBar title. With neither [title] nor [titleWidget] there is no AppBar,
  /// and no Scaffold either — the screen is just [child] over the background.
  final String? title;

  /// A title that depends on state (Azkar names the collection it loaded).
  /// It inherits the AppBar's gold title style, so a plain Text is enough.
  final Widget? titleWidget;

  /// Whether to inset [child] for the system UI. The top inset is skipped when
  /// there is an AppBar, which already covers it.
  final bool safeArea;

  final Widget child;

  const AppBackground({
    super.key,
    required this.image,
    required this.child,
    this.title,
    this.titleWidget,
    this.safeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleChild = titleWidget ?? (title == null ? null : Text(title!));
    final hasAppBar = titleChild != null;

    final body = safeArea ? SafeArea(top: !hasAppBar, child: child) : child;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: image.provider(), fit: BoxFit.cover),
      ),
      child: !hasAppBar
          ? body
          : Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                centerTitle: true,
                iconTheme: const IconThemeData(color: AppColors.primaryColor),
                title: titleChild,
                titleTextStyle: theme.textTheme.titleLarge!.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              body: body,
            ),
    );
  }
}
