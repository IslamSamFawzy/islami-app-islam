import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/theme/app_colors.dart';
import 'package:islami/core/theme/theme_manager.dart';
import 'package:islami/core/widgets/empty_message.dart';
import 'package:islami/core/widgets/error_view.dart';
import 'package:islami/core/widgets/loading_view.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        theme: ThemeManager.darkTheme(),
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('LoadingView shows the gold spinner', (tester) async {
    await pump(tester, const LoadingView());

    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.color, AppColors.primaryColor);
  });

  testWidgets('ErrorView shows the message, and nothing else by default',
      (tester) async {
    await pump(tester, const ErrorView(message: 'Boom'));

    expect(find.text('Boom'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('ErrorView shows an icon and calls onRetry when tapped',
      (tester) async {
    var retries = 0;
    await pump(
      tester,
      ErrorView(
        message: 'No location',
        icon: Icons.location_off_outlined,
        onRetry: () => retries++,
      ),
    );

    expect(find.byIcon(Icons.location_off_outlined), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('EmptyMessage renders cream text, gold when asked',
      (tester) async {
    await pump(tester, const EmptyMessage(message: 'No results'));
    expect(
      tester.widget<Text>(find.text('No results')).style!.color,
      AppColors.textColor,
    );

    await pump(
      tester,
      const EmptyMessage(
        message: 'No radios available',
        color: AppColors.primaryColor,
        dense: true,
      ),
    );
    expect(
      tester.widget<Text>(find.text('No radios available')).style!.color,
      AppColors.primaryColor,
    );
  });
}
