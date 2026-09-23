import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/gen/assets.gen.dart';
import 'package:islami/core/theme/app_colors.dart';
import 'package:islami/core/theme/theme_manager.dart';
import 'package:islami/core/widgets/app_background.dart';
import 'package:islami/core/widgets/header_logo.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(theme: ThemeManager.darkTheme(), home: child),
    );
  }

  testWidgets('AppBackground without a title is just the child on the image',
      (tester) async {
    await pump(
      tester,
      AppBackground(
        image: Assets.images.timeBackground,
        child: const Text('body'),
      ),
    );

    expect(find.byType(AppBar), findsNothing);
    expect(find.text('body'), findsOneWidget);
    expect(find.byType(SafeArea), findsWidgets);
  });

  testWidgets('AppBackground with a title adds the gold transparent AppBar',
      (tester) async {
    await pump(
      tester,
      AppBackground(
        image: Assets.images.timeBackground,
        title: 'Qibla',
        child: const Text('body'),
      ),
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, Colors.transparent);
    expect(appBar.centerTitle, isTrue);
    expect(appBar.titleTextStyle!.color, AppColors.primaryColor);
    expect(find.text('Qibla'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('AppBackground takes a title widget driven by state',
      (tester) async {
    await pump(
      tester,
      AppBackground(
        image: Assets.images.timeBackground,
        titleWidget: const Text('Morning Azkar'),
        child: const Text('body'),
      ),
    );

    expect(find.text('Morning Azkar'), findsOneWidget);
  });

  testWidgets('AppBackground leaves the insets alone when asked',
      (tester) async {
    await pump(
      tester,
      AppBackground(
        image: Assets.images.timeBackground,
        safeArea: false,
        child: const Text('body'),
      ),
    );

    expect(find.byType(SafeArea), findsNothing);
  });

  testWidgets('HeaderLogo sizes the wordmark by a fraction of the width',
      (tester) async {
    await pump(
      tester,
      const Scaffold(body: HeaderLogo(widthFactor: 0.5)),
    );

    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(tester.widget<Image>(find.byType(Image)).width, width * 0.5);
  });
}
