import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/qibla/presentation/widgets/qibla_compass.dart';

void main() {
  // The dial and needle are drawn with CustomPainter; this guards against
  // layout/paint regressions we can't eyeball on a device.
  testWidgets('paints across heading and aligned states without throwing',
      (tester) async {
    Future<void> pump(double? heading, bool aligned) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: QiblaCompass(
                  heading: heading,
                  qiblaBearing: 136,
                  isAligned: aligned,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350)); // finish rotation
    }

    // No heading yet (dial rests with N up).
    await pump(null, false);
    expect(find.byType(QiblaCompass), findsOneWidget);
    expect(tester.takeException(), isNull);

    // A heading arrives — exercises the shortest-path rotation update.
    await pump(40, false);
    expect(tester.takeException(), isNull);

    // Aligned — exercises the glow / brightened-needle branch.
    await pump(136, true);
    expect(tester.takeException(), isNull);
  });
}
