import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/radio/domain/entities/radio_station.dart';
import 'package:islami/features/radio/domain/entities/reciter.dart';
import 'package:islami/features/radio/presentation/bloc/radio_bloc.dart';

void main() {
  const radios = [
    RadioStation(id: 1, name: 'إذاعة القرآن الكريم', url: 'u1'),
    RadioStation(id: 2, name: 'Makkah Live', url: 'u2'),
  ];
  const reciters = [
    Reciter(id: 1, name: 'مشاري راشد العفاسي', moshafServer: 's/', surahList: [1]),
    Reciter(id: 2, name: 'Abdul Basit', moshafServer: 's/', surahList: [1]),
  ];

  const base = RadioState(
    status: RadioStatus.success,
    radios: radios,
    reciters: reciters,
  );

  test('empty query returns everything', () {
    expect(base.filteredRadios, radios);
    expect(base.filteredReciters, reciters);
  });

  test('filters radios by name (Latin + Arabic, article-insensitive)', () {
    expect(base.copyWith(query: 'makkah').filteredRadios,
        [radios[1]]);
    // "قران" (no article, no hamza) should still match "إذاعة القرآن الكريم".
    expect(base.copyWith(query: 'قران').filteredRadios, [radios[0]]);
  });

  test('filters reciters by name', () {
    expect(base.copyWith(query: 'basit').filteredReciters, [reciters[1]]);
    expect(base.copyWith(query: 'العفاسي').filteredReciters, [reciters[0]]);
  });

  test('no match yields an empty list', () {
    expect(base.copyWith(query: 'zzz').filteredRadios, isEmpty);
    expect(base.copyWith(query: 'zzz').filteredReciters, isEmpty);
  });
}
