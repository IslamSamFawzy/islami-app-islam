// CI-style checks of the generated Mushaf assets against their source, run
// with `flutter test`. tool/verify_mushaf_assets.py runs these and more (the
// Tanzil skeleton cross-check and a determinism rebuild).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _sajdahAyat = {
  '7:206', '13:15', '16:50', '17:109', '19:58', '22:18', '22:77', '25:60',
  '27:26', '32:15', '38:24', '41:38', '53:62', '84:21', '96:19',
};

dynamic _json(String path) => jsonDecode(File(path).readAsStringSync());

void main() {
  late Map<String, dynamic> meta;
  late List<Map<String, dynamic>> pages;
  late Map<String, String> source;
  late Map<String, int> sourcePage;

  setUpAll(() {
    meta = _json('assets/quran/meta.json') as Map<String, dynamic>;
    pages = [
      for (var p = 1; p <= 604; p++)
        _json('assets/quran/pages/${p.toString().padLeft(3, '0')}.json')
            as Map<String, dynamic>,
    ];
    // The KFGQPC file starts with a BOM.
    final raw = File('tool/quran_source/kfgqpc/hafsData_v2-0.json')
        .readAsStringSync()
        .replaceFirst('\uFEFF', '');
    final rows = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    source = {for (final r in rows) '${r['sura_no']}:${r['aya_no']}': r['aya_text'] as String};
    sourcePage = {for (final r in rows) '${r['sura_no']}:${r['aya_no']}': r['page'] as int};
  });

  /// Every ayah rebuilt from the page assets, and the page it starts on.
  ({Map<String, String> text, Map<String, int> page}) rebuild() {
    final text = <String, String>{};
    final page = <String, int>{};
    for (final p in pages) {
      for (final line in p['lines'] as List) {
        if (line['t'] != 'a') continue;
        for (final seg in line['segs'] as List) {
          final key = '${seg[0]}:${seg[1]}';
          final toks = (seg[3] as List).cast<String>();
          final seps = seg[4] as String;
          page.putIfAbsent(key, () => p['p'] as int);
          final b = StringBuffer(text[key] ?? '');
          for (var i = 0; i < toks.length; i++) {
            b.write(toks[i]);
            if (i < seps.length) b.write(seps[i]);
          }
          text[key] = b.toString();
        }
      }
    }
    return (text: text, page: page);
  }

  test('counts: 114 suras, 6236 ayat, 604 pages, 30 juz, 240 quarters', () {
    expect(meta['suras'], hasLength(114));
    final ayahs = meta['ayahs'] as List;
    expect(ayahs.fold<int>(0, (n, s) => n + (s as List).length), 6236);
    expect(pages, hasLength(604));
    expect(meta['juz'], hasLength(30));
    expect(meta['quarters'], hasLength(240));
  });

  test('15 lines a page, 8 on pages 1 and 2; 114 headers, 112 basmalas', () {
    var headers = 0, basmalas = 0;
    for (final p in pages) {
      final lines = p['lines'] as List;
      expect(lines, hasLength((p['p'] as int) <= 2 ? 8 : 15), reason: 'page ${p['p']}');
      headers += lines.where((l) => l['t'] == 's').length;
      basmalas += lines.where((l) => l['t'] == 'b').length;
    }
    expect(headers, 114);
    expect(basmalas, 112);
  });

  test('round trip: every ayah rebuilt from the pages equals the source', () {
    final rebuilt = rebuild().text;
    expect(rebuilt.length, 6236);
    final differ = [for (final k in source.keys) if (rebuilt[k] != source[k]) k];
    expect(differ, isEmpty);
  });

  test('every ayah is on the page the KFGQPC data gives', () {
    final page = rebuild().page;
    final differ = [for (final k in source.keys) if (page[k] != sourcePage[k]) k];
    expect(differ, isEmpty);
  });

  test('the basmala is 1:1 without its ayah mark', () {
    final toks = (meta['basmala'] as List).cast<String>();
    final seps = meta['basmala_seps'] as String;
    final b = StringBuffer();
    for (var i = 0; i < toks.length; i++) {
      b.write(toks[i]);
      if (i < seps.length) b.write(seps[i]);
    }
    final ayah = source['1:1']!;
    // The basmala, then an NBSP and the one-codepoint ayah mark.
    expect(ayah.substring(0, ayah.length - 2), b.toString());
  });

  test('anchors: Al-Baqarah p2, 18:1 p293, An-Nas p604', () {
    final page = rebuild().page;
    expect((meta['suras'] as List)[1]['page'], 2);
    expect(page['18:1'], 293);
    expect((meta['suras'] as List)[113]['page'], 604);
  });

  test('print anchors: juz 4 at 3:93 on page 62, juz 11 at 9:93 on page 201, '
      'a rub at 15:49', () {
    expect((meta['juz'] as List)[3], [3, 93]);
    expect(rebuild().page['3:93'], 62);
    expect((meta['juz'] as List)[10], [9, 93]);
    expect(rebuild().page['9:93'], 201);
    expect(meta['quarters'], anyElement(equals([15, 49])));
  });

  test('the 15 sajdah ayat, and only they, are flagged', () {
    final flagged = <String>{};
    final ayahs = meta['ayahs'] as List;
    for (var s = 0; s < ayahs.length; s++) {
      final rows = ayahs[s] as List;
      for (var a = 0; a < rows.length; a++) {
        if ((rows[a] as List)[3] != 0) flagged.add('${s + 1}:${a + 1}');
      }
    }
    expect(flagged, _sajdahAyat);
  });

  test('the fonts ship byte for byte', () {
    expect(File('assets/fonts/uthmanic_hafs_v20.ttf').readAsBytesSync(),
        File('tool/quran_source/kfgqpc/uthmanic_hafs_v20.ttf').readAsBytesSync());
    expect(File('assets/fonts/surah-name-v4.ttf').readAsBytesSync(),
        File('tool/quran_source/qul/surah-name-v4.ttf').readAsBytesSync());
  });
}
