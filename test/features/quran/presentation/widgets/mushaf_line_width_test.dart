import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/quran/data/datasources/mushaf_local_data_source.dart';
import 'package:islami/features/quran/domain/entities/mushaf_page.dart';
import 'package:islami/features/quran/presentation/widgets/mushaf_page_widget.dart';

/// Every justified line must fit the page with at least the minimum gap
/// between its words, or the page widget would have to shrink it. Measured
/// with the real Hafs font.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every ayah line fits in the page width', () async {
    final font = File('assets/fonts/uthmanic_hafs_v20.ttf').readAsBytesSync();
    await (FontLoader(MushafPageWidget.fontFamily)
          ..addFont(Future.value(ByteData.sublistView(font))))
        .load();

    const fontSize = 100.0;
    final source = MushafLocalDataSourceImpl();
    final widths = <(int, int, double)>[];
    for (var p = 1; p <= 604; p++) {
      final lines = await source.getPageLines(p);
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line is! AyahLine) continue;
        var width = 0.0;
        for (final w in line.words) {
          if (w.kind == MushafWordKind.empty) continue;
          final painter = TextPainter(
            text: TextSpan(
              text: w.text,
              style: const TextStyle(
                fontFamily: MushafPageWidget.fontFamily,
                fontSize: fontSize,
              ),
            ),
            textDirection: TextDirection.rtl,
          )..layout();
          width += painter.width;
          painter.dispose();
        }
        final gaps =
            line.words.where((w) => w.kind != MushafWordKind.empty).length - 1;
        widths.add(
          (p, i + 1, width / fontSize + gaps * MushafPageWidget.minGapInEm),
        );
      }
    }
    widths.sort((a, b) => b.$3.compareTo(a.$3));
    // ignore: avoid_print
    print('widest lines (page, line, em): ${widths.take(3).toList()}');
    expect(widths.length, 8820);
    expect(widths.first.$3, lessThan(MushafPageWidget.widthInEm));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
