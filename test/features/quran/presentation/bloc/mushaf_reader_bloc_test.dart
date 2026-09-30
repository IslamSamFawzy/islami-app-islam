import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/error/failures.dart';
import 'package:islami/features/quran/data/datasources/mushaf_local_data_source.dart';
import 'package:islami/features/quran/data/repositories/mushaf_repository_impl.dart';
import 'package:islami/features/quran/domain/entities/ayah_ref.dart';
import 'package:islami/features/quran/domain/entities/reading_progress.dart';
import 'package:islami/features/quran/domain/entities/sura.dart';
import 'package:islami/features/quran/domain/repositories/quran_repository.dart';
import 'package:islami/features/quran/domain/usecases/add_recent_sura.dart';
import 'package:islami/features/quran/domain/usecases/get_juz_start.dart';
import 'package:islami/features/quran/domain/usecases/get_mushaf_page.dart';
import 'package:islami/features/quran/domain/usecases/get_page_for_ayah.dart';
import 'package:islami/features/quran/domain/usecases/get_reading_progress.dart';
import 'package:islami/features/quran/domain/usecases/get_sura_info.dart';
import 'package:islami/features/quran/domain/usecases/save_reading_progress.dart';
import 'package:islami/features/quran/presentation/bloc/mushaf/mushaf_reader_bloc.dart';

class _FakeQuranRepository implements QuranRepository {
  final Map<int, ReadingProgress> progress = {};
  final List<ReadingProgress> saved = [];
  final List<int> recents = [];

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
  Future<Either<Failure, Unit>> addRecentSura(int suraId) async {
    recents.add(suraId);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<Sura>>> getAllSuras() async => const Right([]);
  @override
  Future<Either<Failure, List<Sura>>> getRecentSuras() async =>
      const Right([]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeQuranRepository quran;
  late MushafRepositoryImpl mushaf;

  setUp(() {
    quran = _FakeQuranRepository();
    mushaf = MushafRepositoryImpl(localDataSource: MushafLocalDataSourceImpl());
  });

  MushafReaderBloc build() => MushafReaderBloc(
    getPage: GetPage(mushaf),
    getPageForAyah: GetPageForAyah(mushaf),
    getSuraInfo: GetSuraInfo(mushaf),
    getJuzStart: GetJuzStart(mushaf),
    getReadingProgress: GetReadingProgress(quran),
    saveReadingProgress: SaveReadingProgress(quran),
    addRecentSura: AddRecentSura(quran),
  );

  Future<MushafReaderState> opened(MushafReaderBloc bloc) =>
      bloc.stream.firstWhere((s) => s.status.isSuccess);

  test('opening a sura goes to its first page, without saving', () async {
    final bloc = build()..add(const MushafOpenedEvent(4));
    final state = await opened(bloc);

    expect(state.page, 77);
    expect(state.jumpCount, 1);
    expect(state.selected, isNull);
    await bloc.close();
    expect(quran.saved, isEmpty, reason: 'opening is not reading');
  });

  test('resuming opens the saved page and highlights the ayah', () async {
    quran.progress[2] = ReadingProgress(
      suraId: 2,
      ayah: 42,
      updatedAt: DateTime(2026),
    );
    final bloc = build()..add(const MushafOpenedEvent(2, resume: true));
    final state = await opened(bloc);

    expect(state.page, 7);
    expect(state.selected, const AyahRef(2, 42));

    final cleared = await bloc.stream.firstWhere((s) => s.selected == null);
    expect(cleared.page, 7, reason: 'the page stays where it jumped');
    await bloc.close();
  });

  test('resuming a sura never read opens its first page', () async {
    final bloc = build()..add(const MushafOpenedEvent(18, resume: true));
    expect((await opened(bloc)).page, 293);
    await bloc.close();
  });

  test('a saved ayah the sura does not have opens its first page', () async {
    quran.progress[1] = ReadingProgress(
      suraId: 1,
      ayah: 99,
      updatedAt: DateTime(2026),
    );
    final bloc = build()..add(const MushafOpenedEvent(1, resume: true));
    final state = await opened(bloc);
    expect(state.page, 1);
    expect(state.selected, isNull);
    await bloc.close();
  });

  test('swiping to a page saves its first ayah once it settles', () async {
    final bloc = build()..add(const MushafOpenedEvent(2));
    await opened(bloc);

    bloc.add(const MushafPageChangedEvent(3));
    await bloc.stream.firstWhere((s) => s.pages.containsKey(3));
    await Future<void>.delayed(MushafReaderBloc.saveDebounce * 2);

    // Page 3 opens with 2:6.
    expect(quran.saved.single.suraId, 2);
    expect(quran.saved.single.ayah, 6);
    expect(quran.recents, [2]);
    await bloc.close();
  });

  test('tapping an ayah selects it, tapping again clears it', () async {
    final bloc = build()..add(const MushafOpenedEvent(2));
    await opened(bloc);

    bloc.add(const MushafAyahTappedEvent(AyahRef(2, 3)));
    await bloc.stream.firstWhere((s) => s.selected == const AyahRef(2, 3));
    bloc.add(const MushafAyahTappedEvent(AyahRef(2, 3)));
    await bloc.stream.firstWhere((s) => s.selected == null);

    await bloc.close(); // leaving saves at once
    expect(quran.saved.single.ayah, 3);
  });

  test('going to the background saves without waiting', () async {
    final bloc = build()..add(const MushafOpenedEvent(2));
    await opened(bloc);
    bloc.add(const MushafAyahTappedEvent(AyahRef(2, 5)));
    bloc.add(const MushafSaveNowEvent());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(quran.saved.single.ayah, 5);
    await bloc.close();
  });

  group('go to', () {
    Future<MushafReaderState> goTo(MushafTarget target) async {
      final bloc = build()..add(const MushafOpenedEvent(1));
      await opened(bloc);
      bloc.add(MushafGoToEvent(target));
      final state = await bloc.stream.firstWhere((s) => s.jumpCount == 2);
      await bloc.close();
      return state;
    }

    test('a sura', () async {
      expect((await goTo(const SuraTarget(18))).page, 293);
    });

    test('a juz', () async {
      expect((await goTo(const JuzTarget(30))).page, 582);
    });

    test('a page', () async {
      expect((await goTo(const PageTarget(500))).page, 500);
    });

    test('an ayah, highlighted', () async {
      final state = await goTo(const AyahTarget(AyahRef(114, 1)));
      expect(state.page, 604);
      expect(state.selected, const AyahRef(114, 1));
    });

    test('a page out of range goes nowhere', () async {
      final bloc = build()..add(const MushafOpenedEvent(1));
      await opened(bloc);
      bloc.add(const MushafGoToEvent(PageTarget(605)));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(bloc.state.jumpCount, 1);
      expect(bloc.state.page, 1);
      await bloc.close();
    });
  });

  test('keeps only the pages near the one on screen', () async {
    final bloc = build()..add(const MushafOpenedEvent(1));
    await opened(bloc);
    for (final p in [1, 2, 3]) {
      bloc.add(MushafPageNeededEvent(p));
    }
    await bloc.stream.firstWhere((s) => s.pages.length == 3);

    bloc.add(const MushafGoToEvent(PageTarget(300)));
    final state = await bloc.stream.firstWhere(
      (s) => s.pages.containsKey(300),
    );
    expect(state.pages.keys.every((p) => (p - 300).abs() <= 2), isTrue);
    await bloc.close();
  });
}
