import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/constants/sura_names.dart';

void main() {
  group('SuraNames', () {
    test('holds exactly 114 suras, numbered 1..114 in order', () {
      expect(SuraNames.all.length, 114);
      for (var i = 0; i < SuraNames.all.length; i++) {
        expect(SuraNames.all[i].number, i + 1);
      }
    });

    test('byNumber resolves known suras', () {
      final first = SuraNames.byNumber(1)!;
      expect(first.nameEn, 'Al-Fatiha');
      expect(first.nameAr, 'الفاتحه');

      final second = SuraNames.byNumber(2)!;
      expect(second.nameEn, 'Al-Baqarah');
      expect(second.nameAr, 'البقرة');

      final last = SuraNames.byNumber(114)!;
      expect(last.nameEn, 'An-Nas');
      expect(last.nameAr, 'الناس');
    });

    test('byNumber returns null out of range', () {
      expect(SuraNames.byNumber(0), isNull);
      expect(SuraNames.byNumber(115), isNull);
      expect(SuraNames.byNumber(-1), isNull);
    });
  });
}
