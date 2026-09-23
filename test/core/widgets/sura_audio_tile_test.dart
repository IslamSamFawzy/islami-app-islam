import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/theme/theme_manager.dart';
import 'package:islami/core/widgets/play_pause_button.dart';
import 'package:islami/core/widgets/sura_audio_tile.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        theme: ThemeManager.darkTheme(),
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('shows the number and both names of a known sura',
      (tester) async {
    await pump(
      tester,
      SuraAudioTile(suraId: '2', isPlaying: false, onPlayPause: () {}),
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.text('Al-Baqarah'), findsOneWidget);
    expect(find.text('البقرة'), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
  });

  testWidgets('falls back to "Sura N" when the number is unknown',
      (tester) async {
    await pump(
      tester,
      SuraAudioTile(suraId: '999', isPlaying: true, onPlayPause: () {}),
    );

    expect(find.text('Sura 999'), findsOneWidget);
    expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
  });

  testWidgets('renders the trailing slot and reports taps', (tester) async {
    var taps = 0;
    await pump(
      tester,
      SuraAudioTile(
        suraId: '2',
        isPlaying: false,
        onPlayPause: () => taps++,
        trailing: const Icon(Icons.download_rounded),
      ),
    );

    expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    await tester.tap(find.byType(PlayPauseButton));
    expect(taps, 1);
  });

  testWidgets('highlighted draws a border around the row', (tester) async {
    await pump(
      tester,
      SuraAudioTile(
        suraId: '2',
        isPlaying: true,
        highlighted: true,
        onPlayPause: () {},
      ),
    );

    final decoration =
        tester.widget<Container>(find.byType(Container)).decoration
            as BoxDecoration;
    expect(decoration.border, isNotNull);
  });
}
