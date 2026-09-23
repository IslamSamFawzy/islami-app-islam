import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/prayer_guide/domain/entities/prayer_posture.dart';
import 'package:islami/features/prayer_guide/presentation/widgets/animated_prayer_figure.dart';

void main() {
  testWidgets('loops through every posture without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 320,
          height: 220,
          child: AnimatedPrayerFigure(postures: PrayerPosture.values),
        ),
      ),
    );
    // One full cycle is 11 postures x 1.7 s.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a single posture is drawn still', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AnimatedPrayerFigure(postures: [PrayerPosture.sujud]),
      ),
    );
    expect(tester.hasRunningAnimations, isFalse);
  });
}
