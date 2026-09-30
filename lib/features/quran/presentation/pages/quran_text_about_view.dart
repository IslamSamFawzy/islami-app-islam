import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Where the Mushaf's text, font, layout and data come from, credited as
/// their terms ask (see tool/quran_source/SOURCE.md).
class QuranTextAboutView extends StatelessWidget {
  static const String routeName = '/quran-text-about';

  const QuranTextAboutView({super.key});

  static const List<_Credit> _credits = [
    _Credit(
      title: 'Quran text and Uthmanic Hafs font',
      body:
          'The Quran text (Hafs ʿan ʿĀṣim) and the "KFGQPC HAFS Uthmanic '
          'Script" font, version 2.0, are by the King Fahd Glorious Quran '
          'Printing Complex (KFGQPC), Madinah. They are shown exactly as '
          'published; the font is not modified.',
      link: 'https://qurancomplex.gov.sa',
    ),
    _Credit(
      title: 'Page layout and sura names',
      body:
          'The 604-page, 15-line layout of the Madinah Mushaf (1421H print) '
          'and the sura-name font are from the Quranic Universal Library '
          '(QUL) by Tarteel.',
      link: 'https://qul.tarteel.ai',
    ),
    _Credit(
      title: 'Juz, hizb and sajdah data',
      body:
          'Juz and quarter starts and the sajdah types are from the Tanzil '
          'Project\'s Quran metadata, licensed CC BY. The text was also '
          'checked letter by letter against Tanzil\'s Uthmani text.',
      link: 'https://tanzil.net',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.primaryColor),
        title: const Text('About the Quran text'),
        titleTextStyle: theme.textTheme.titleLarge!.copyWith(
          color: AppColors.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final credit in _credits) ...[
            Text(
              credit.title,
              style: theme.textTheme.titleMedium!.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              credit.body,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              credit.link,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: AppColors.primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

class _Credit {
  final String title;
  final String body;
  final String link;

  const _Credit({required this.title, required this.body, required this.link});
}
