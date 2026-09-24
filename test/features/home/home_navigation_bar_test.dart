import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/theme/theme_manager.dart';
import 'package:islami/features/home/presentation/widgets/home_navigation_bar.dart';

void main() {
  Future<void> pumpAt(
    WidgetTester tester, {
    required double width,
    int currentIndex = 0,
    ValueChanged<int>? onTap,
  }) async {
    tester.view.physicalSize = Size(width * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeManager.darkTheme(),
        home: Scaffold(
          bottomNavigationBar: HomeNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap ?? (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('has one tab per screen, Salah last', (tester) async {
    await pumpAt(tester, width: 412);

    expect(find.text('Quran'), findsOneWidget);
    expect(find.text('Salah'), findsOneWidget);
    final bar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(bar.items.map((i) => i.label), [
      'Quran',
      'Hadith',
      'Sebha',
      'Radio',
      'Time',
      'Salah',
    ]);
  });

  testWidgets('six tabs fit a 360dp screen, whichever is selected',
      (tester) async {
    // The narrow phone the design has to survive: 360 / 6 = 60dp per tab.
    for (var index = 0; index < 6; index++) {
      await pumpAt(tester, width: 360, currentIndex: index);
      expect(
        tester.takeException(),
        isNull,
        reason: 'tab $index overflows at 360dp',
      );
    }
  });

  testWidgets('reports the tab that was tapped', (tester) async {
    var tapped = -1;
    await pumpAt(tester, width: 412, onTap: (index) => tapped = index);

    await tester.tap(find.text('Salah'));
    expect(tapped, 5);
  });
}
