import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/utils/arabic_search.dart';

/// Each ayah's text from the two sources, as they were downloaded (see
/// tool/quran_source/SOURCE.md). Nothing here is typed by hand.
({Map<String, String> kfgqpc, Map<String, String> tanzil}) _sources() {
  final raw = File(
    'tool/quran_source/kfgqpc/hafsData_v2-0.json',
  ).readAsStringSync().replaceFirst('﻿', '');
  final kfgqpc = <String, String>{};
  for (final r in (jsonDecode(raw) as List).cast<Map<String, dynamic>>()) {
    final text = r['aya_text'] as String;
    // Without its ayah-number codepoint and the space before it.
    kfgqpc['${r['sura_no']}:${r['aya_no']}'] = text.substring(
      0,
      text.length - 2,
    );
  }
  final tanzil = <String, String>{};
  for (final line in File(
    'tool/quran_source/tanzil/quran-uthmani.txt',
  ).readAsLinesSync()) {
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split('|');
    tanzil['${parts[0]}:${parts[1]}'] = parts.sublist(2).join('|');
  }
  return (kfgqpc: kfgqpc, tanzil: tanzil);
}

/// The words of [s] as search sees them, joined without spaces (the two
/// sources split a few words differently).
String _letters(String s, {int skipWords = 0}) => s
    .split(RegExp(r'[  ]+'))
    .skip(skipWords)
    .map(ArabicSearch.normalize)
    .join();

void main() {
  group('normalize', () {
    test('strips tashkeel (shadda etc.)', () {
      // النّور (with shadda) folds to the same as النور.
      expect(ArabicSearch.normalize('النّور'), ArabicSearch.normalize('النور'));
      expect(ArabicSearch.normalize('النور'), 'نور');
    });

    test('unifies alef variants', () {
      expect(ArabicSearch.normalize('الأعراف'), 'اعراف');
      expect(ArabicSearch.normalize('الاعراف'), 'اعراف');
      expect(ArabicSearch.normalize('إبراهيم'), 'ابراهيم');
      expect(ArabicSearch.normalize('آدم'), 'ادم'); // alef-madda -> alef
    });

    test('folds teh marbuta and alef maksura', () {
      expect(ArabicSearch.normalize('البقرة'), 'بقره');
      expect(ArabicSearch.normalize('بقره'), 'بقره');
      expect(ArabicSearch.normalize('موسى'), ArabicSearch.normalize('موسي'));
    });

    test('removes tatweel', () {
      expect(
        ArabicSearch.normalize('الرحـــمن'),
        ArabicSearch.normalize('الرحمن'),
      );
    });

    test('drops a leading definite article', () {
      expect(ArabicSearch.normalize('الفلق'), 'فلق');
      expect(ArabicSearch.normalize('الناس'), 'ناس');
    });

    test('preserves letters and digits (does not over-strip)', () {
      expect(ArabicSearch.normalize('محمد'), 'محمد');
      expect(ArabicSearch.normalize('114'), '114');
    });

    test('lower-cases Latin, leaves it otherwise intact', () {
      expect(ArabicSearch.normalize('Al-Baqarah'), 'al-baqarah');
    });
  });

  group('matches', () {
    test('is diacritic/hamza/article insensitive', () {
      expect(ArabicSearch.matches('بقره', 'البقرة'), isTrue);
      expect(ArabicSearch.matches('الاعراف', 'الأعراف'), isTrue);
      expect(ArabicSearch.matches('nisa', "An-Nisa'"), isTrue);
    });

    test('empty query matches everything; nonsense matches nothing', () {
      expect(ArabicSearch.matches('', 'البقرة'), isTrue);
      expect(ArabicSearch.matches('zzz', 'البقرة'), isFalse);
    });
  });

  group('suraMatches', () {
    bool q(String query) => ArabicSearch.suraMatches(
      query: query,
      number: 2,
      nameEn: 'Al-Baqarah',
      nameAr: 'البقرة',
    );

    test('matches by number, English or Arabic (2 / baqara / بقرة / بقره)', () {
      expect(q('2'), isTrue);
      expect(q('baqara'), isTrue);
      expect(q('بقرة'), isTrue);
      expect(q('بقره'), isTrue);
    });

    test('empty matches, unrelated does not', () {
      expect(q(''), isTrue);
      expect(q('zzz'), isFalse);
    });

    test('Arabic query hits Al-A\'raf via nameAr', () {
      expect(
        ArabicSearch.suraMatches(
          query: 'الاعراف',
          number: 7,
          nameEn: "Al-A'raf",
          nameAr: 'الأعراف',
        ),
        isTrue,
      );
    });
  });

  group('the two Quran sources search the same', () {
    final sources = _sources();

    test('2:72: hamza as a letter (KFGQPC) or as a mark (Tanzil)', () {
      final kfgqpc = sources.kfgqpc['2:72']!;
      final tanzil = sources.tanzil['2:72']!;
      // The sources really do differ here: U+0621 in one, U+0654 in the other.
      expect(kfgqpc, contains('ءۡ'));
      expect(tanzil, contains('ْٔ'));

      expect(_letters(kfgqpc), _letters(tanzil));
      // Each finds the other's word.
      final kWord = kfgqpc.split(' ').firstWhere((w) => w.contains('ء'));
      final tWord = tanzil.split(' ').firstWhere((w) => w.contains('ٔ'));
      expect(ArabicSearch.matches(kWord, tanzil), isTrue);
      expect(ArabicSearch.matches(tWord, kfgqpc), isTrue);
    });

    test('every ayah folds to the same letters from either source', () {
      final basmalaWords = sources.tanzil['1:1']!.split(' ').length;
      final differ = <String>[];
      sources.kfgqpc.forEach((key, kfgqpc) {
        final (sura, ayah) = (key.split(':')[0], key.split(':')[1]);
        // Tanzil puts the basmala before 1 of every sura but 1 and 9.
        final withBasmala = ayah == '1' && sura != '1' && sura != '9';
        final tanzil = _letters(
          sources.tanzil[key]!,
          skipWords: withBasmala ? basmalaWords : 0,
        );
        if (_letters(kfgqpc) != tanzil) differ.add(key);
      });
      expect(differ, isEmpty);
    });
  });
}
