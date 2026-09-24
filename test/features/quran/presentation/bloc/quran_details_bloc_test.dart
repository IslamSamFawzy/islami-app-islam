import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/error/failures.dart';
import 'package:islami/features/quran/domain/entities/reading_progress.dart';
import 'package:islami/features/quran/domain/entities/sura.dart';
import 'package:islami/features/quran/domain/repositories/quran_repository.dart';
import 'package:islami/features/quran/domain/usecases/get_reading_progress.dart';
import 'package:islami/features/quran/domain/usecases/get_sura_verses.dart';
import 'package:islami/features/quran/domain/usecases/save_reading_progress.dart';
import 'package:islami/features/quran/presentation/bloc/details/quran_details_bloc.dart';

class _FakeRepository implements QuranRepository {
  final List<String> verses;
  final Map<int, ReadingProgress> progress = {};
  final List<ReadingProgress> saved = [];

  _FakeRepository(this.verses);

  @override
  Future<Either<Failure, List<String>>> getSuraVerses(int suraId) async =>
      Right(verses);

  @override
  Future<Either<Failure, ReadingProgress?>> getProgress(int suraId) async =>
      Right(progress[suraId]);

  @override
  Future<Either<Failure, Unit>> saveProgress(ReadingProgress p) async {
    saved.add(p);
    progress[p.suraId] = p;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<Sura>>> getAllSuras() async => const Right([]);
  @override
  Future<Either<Failure, List<Sura>>> getRecentSuras() async => const Right([]);
  @override
  Future<Either<Failure, Unit>> addRecentSura(int suraId) async =>
      const Right(unit);
}

void main() {
  late _FakeRepository repository;

  QuranDetailsBloc build() => QuranDetailsBloc(
    getSuraVerses: GetSuraVerses(repository),
    getReadingProgress: GetReadingProgress(repository),
    saveReadingProgress: SaveReadingProgress(repository),
  );

  setUp(() {
    repository = _FakeRepository([for (var i = 1; i <= 50; i++) 'Ayah $i']);
  });

  test('opening from the list starts at the top', () async {
    repository.progress[2] = ReadingProgress(
      suraId: 2,
      ayahIndex: 20,
      updatedAt: DateTime(2026),
    );
    final bloc = build();

    bloc.add(const LoadVersesEvent(2));
    final state = await bloc.stream.firstWhere((s) => s.verses.isNotEmpty);

    expect(state.initialIndex, -1);
    expect(state.selectedIndex, -1);
    await bloc.close();
  });

  test('resuming opens at the saved ayah and highlights it', () async {
    repository.progress[2] = ReadingProgress(
      suraId: 2,
      ayahIndex: 20,
      updatedAt: DateTime(2026),
    );
    final bloc = build();

    bloc.add(const LoadVersesEvent(2, resume: true));
    final state = await bloc.stream.firstWhere((s) => s.verses.isNotEmpty);

    expect(state.initialIndex, 20);
    expect(state.selectedIndex, 20, reason: 'briefly highlighted');
    await bloc.close();
  });

  test('a sura never read still opens at the top', () async {
    final bloc = build();

    bloc.add(const LoadVersesEvent(2, resume: true));
    final state = await bloc.stream.firstWhere((s) => s.verses.isNotEmpty);

    expect(state.initialIndex, -1);
    await bloc.close();
  });

  test('a saved ayah beyond the sura is ignored', () async {
    repository.progress[2] = ReadingProgress(
      suraId: 2,
      ayahIndex: 999,
      updatedAt: DateTime(2026),
    );
    final bloc = build();

    bloc.add(const LoadVersesEvent(2, resume: true));
    final state = await bloc.stream.firstWhere((s) => s.verses.isNotEmpty);

    expect(state.initialIndex, -1);
    await bloc.close();
  });

  test('scrolling saves once, after it settles', () async {
    final bloc = build();
    bloc.add(const LoadVersesEvent(2));
    await bloc.stream.firstWhere((s) => s.verses.isNotEmpty);

    // A scroll reports a new ayah on every frame.
    for (var i = 1; i <= 8; i++) {
      bloc.add(VerseVisibleEvent(i));
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(repository.saved, isEmpty, reason: 'still scrolling');

    await Future<void>.delayed(QuranDetailsBloc.saveDebounce * 2);

    expect(repository.saved.length, 1);
    expect(repository.saved.single.ayahIndex, 8);
    expect(repository.saved.single.suraId, 2);
    await bloc.close();
  });

  test('leaving the screen saves the last position straight away', () async {
    final bloc = build();
    bloc.add(const LoadVersesEvent(2));
    await bloc.stream.firstWhere((s) => s.verses.isNotEmpty);
    bloc.add(const VerseVisibleEvent(12));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await bloc.close(); // the debounce has not fired yet

    expect(repository.saved.single.ayahIndex, 12);
  });

  test('going to the background saves without waiting', () async {
    final bloc = build();
    bloc.add(const LoadVersesEvent(2));
    await bloc.stream.firstWhere((s) => s.verses.isNotEmpty);
    bloc.add(const VerseVisibleEvent(4));

    bloc.add(const SaveProgressNowEvent());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(repository.saved.single.ayahIndex, 4);
    await bloc.close();
  });

  test('the resume highlight clears itself', () async {
    repository.progress[2] = ReadingProgress(
      suraId: 2,
      ayahIndex: 3,
      updatedAt: DateTime(2026),
    );
    final bloc = build();

    bloc.add(const LoadVersesEvent(2, resume: true));
    await bloc.stream.firstWhere((s) => s.selectedIndex == 3);

    final cleared = await bloc.stream.firstWhere((s) => s.selectedIndex == -1);
    expect(cleared.initialIndex, 3, reason: 'the list stays where it jumped');
    await bloc.close();
  });
}
