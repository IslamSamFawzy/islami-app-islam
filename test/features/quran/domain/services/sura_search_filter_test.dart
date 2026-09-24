import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/quran/domain/entities/sura.dart';
import 'package:islami/features/quran/domain/services/sura_search_filter.dart';

void main() {
  const fatiha = Sura(id: 1, nameEn: 'Al-Fatiha', nameAr: 'الفاتحه', ayaCount: 7);
  const baqarah = Sura(
    id: 2,
    nameEn: 'Al-Baqarah',
    nameAr: 'البقرة',
    ayaCount: 286,
  );
  const suras = [fatiha, baqarah];

  final filter = DefaultSuraSearchFilter();

  test('an empty query returns everything', () {
    expect(filter.filter(suras, '   '), suras);
  });

  test('matches the English name, case-insensitively', () {
    expect(filter.filter(suras, 'baqarah'), [baqarah]);
    expect(filter.filter(suras, 'FATIHA'), [fatiha]);
  });

  test('matches the sura number', () {
    expect(filter.filter(suras, '2'), [baqarah]);
  });

  test('matches Arabic without the article or the hamza', () {
    // "بقره": no "ال", teh marbuta instead of the original spelling.
    expect(filter.filter(suras, 'بقره'), [baqarah]);
    expect(filter.filter(suras, 'الفاتحة'), [fatiha]);
  });

  test('no match yields an empty list', () {
    expect(filter.filter(suras, 'zzz'), isEmpty);
  });
}
