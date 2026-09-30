import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/quran/data/datasources/mushaf_local_data_source.dart';
import 'package:islami/features/quran/data/repositories/mushaf_repository_impl.dart';
import 'package:islami/features/quran/domain/entities/ayah_ref.dart';
import 'package:islami/features/quran/domain/entities/mushaf_page.dart';
import 'package:islami/features/quran/presentation/widgets/mushaf_page_widget.dart';

void main() {
  late MushafPage page2;
  late MushafPage page3;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // The real fonts, so lines measure as they do on a phone.
    for (final (family, file) in [
      (MushafPageWidget.fontFamily, 'assets/fonts/uthmanic_hafs_v20.ttf'),
      ('SurahName', 'assets/fonts/surah-name-v4.ttf'),
    ]) {
      final bytes = File(file).readAsBytesSync();
      await (FontLoader(family)
            ..addFont(Future.value(ByteData.sublistView(bytes))))
          .load();
    }
    final repo = MushafRepositoryImpl(
      localDataSource: MushafLocalDataSourceImpl(),
    );
    page2 = (await repo.getPage(2)).getOrElse(() => throw 'page 2');
    page3 = (await repo.getPage(3)).getOrElse(() => throw 'page 3');
  });

  Future<List<AyahRef>> pump(
    WidgetTester tester,
    MushafPage page, {
    AyahRef? selected,
  }) async {
    final taps = <AyahRef>[];
    // A phone-sized screen, 400 x 800 logical pixels.
    tester.view
      ..physicalSize = const Size(1200, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 750,
            child: MushafPageWidget(
              page: page,
              selected: selected,
              onAyahTap: taps.add,
            ),
          ),
        ),
      ),
    );
    return taps;
  }

  testWidgets('a full page is 15 equal line slots', (tester) async {
    await pump(tester, page3);
    final slots = tester
        .widgetList<SizedBox>(
          find.descendant(
            of: find.byType(Column),
            matching: find.byWidgetPredicate(
              (w) => w is SizedBox && w.height == 750 / 15,
            ),
          ),
        )
        .toList();
    expect(slots, hasLength(15));
  });

  testWidgets('screen readers hear the sura and each ayah', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, page2);

    expect(find.bySemanticsLabel('Sura Al-Baqarah, البقرة'), findsOneWidget);
    expect(find.bySemanticsLabel('Sura Al-Baqarah, ayah 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Sura Al-Baqarah, ayah 5'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('tapping a word taps its ayah', (tester) async {
    final taps = await pump(tester, page2);
    final word = page2.words.firstWhere((w) => w.sura == 2 && w.ayah == 2);

    await tester.tap(find.text(word.text).first);
    expect(taps, [const AyahRef(2, 2)]);
  });

  testWidgets('a tap between two words counts for the word before', (
    tester,
  ) async {
    final taps = await pump(tester, page3);
    // Page 3 line 1 is 2:6 from its first word; right to left, the gap
    // after the first word lies just left of it.
    final first = page3.words.firstWhere((w) => w.text.isNotEmpty);
    final rect = tester.getRect(find.text(first.text).first);
    await tester.tapAt(rect.centerLeft - const Offset(4, 0));
    expect(taps, [AyahRef(first.sura, first.ayah)]);
  });

  testWidgets('the selected ayah is in gold, and only it', (tester) async {
    await pump(tester, page2, selected: const AyahRef(2, 3));

    final highlighted = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .where((b) => b.decoration is BoxDecoration)
        .where((b) => (b.decoration as BoxDecoration).color != null)
        .length;
    final ayah3 = page2.words
        .where((w) => w.sura == 2 && w.ayah == 3)
        .where((w) => w.kind != MushafWordKind.empty)
        .length;
    expect(highlighted, ayah3);
  });
}
