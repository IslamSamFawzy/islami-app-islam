import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/quran/presentation/pages/quran_text_about_view.dart';

void main() {
  testWidgets('credits the text, the layout and the data, with links', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: QuranTextAboutView()));

    expect(find.textContaining('King Fahd Glorious Quran'), findsOneWidget);
    expect(find.textContaining('Quranic Universal Library'), findsOneWidget);
    expect(find.textContaining('Tanzil'), findsOneWidget);
    for (final link in [
      'https://qurancomplex.gov.sa',
      'https://qul.tarteel.ai',
      'https://tanzil.net',
    ]) {
      expect(find.text(link), findsOneWidget);
    }
  });
}
