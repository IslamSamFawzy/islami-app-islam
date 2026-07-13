import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/hadith.dart';

/// Full-text view for a single Hadith (spec §2.5): dark screen, AppBar with a
/// gold back arrow + "Hadith N", the Arabic title, then the scrollable body.
class HadithDetailsView extends StatelessWidget {
  static const String routeName = '/hadith-details';

  const HadithDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as ({Hadith hadith, int number});
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primaryColor),
        title: Text('Hadith ${args.number}'),
        titleTextStyle: theme.textTheme.titleLarge!.copyWith(
          color: AppColors.primaryColor,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              args.hadith.title,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: theme.textTheme.headlineSmall!.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  args.hadith.content,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: theme.textTheme.bodyLarge!.copyWith(
                    color: AppColors.textColor,
                    height: 1.9,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
