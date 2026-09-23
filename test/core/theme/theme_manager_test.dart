import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/theme/theme_manager.dart';

void main() {
  final theme = ThemeManager.darkTheme();

  test('the theme-level font family reaches every text style', () {
    final styles = [
      theme.textTheme.headlineSmall,
      theme.textTheme.headlineLarge,
      theme.textTheme.titleLarge,
      theme.textTheme.bodyLarge,
      theme.textTheme.bodyMedium,
    ];

    for (final style in styles) {
      expect(style!.fontFamily, 'Janna');
    }
  });

  testWidgets('bottom navigation labels render in Janna as well',
      (tester) async {
    // The label style no longer names the family; it inherits it from the
    // ambient text theme. This is the check that it really does.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Quran'),
              BottomNavigationBarItem(icon: Icon(Icons.radio), label: 'Radio'),
            ],
          ),
        ),
      ),
    );

    final label = tester.widget<RichText>(
      find.descendant(of: find.text('Quran'), matching: find.byType(RichText)),
    );
    expect(label.text.style!.fontFamily, 'Janna');
  });
}
