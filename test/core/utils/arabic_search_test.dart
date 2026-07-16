import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/utils/arabic_search.dart';

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
}
