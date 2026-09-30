import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/di/service_locator.dart';
import 'package:islami/core/error/failures.dart';
import 'package:islami/core/utils/formatters.dart';
import 'package:islami/features/quran/data/datasources/mushaf_local_data_source.dart';
import 'package:islami/features/quran/data/repositories/mushaf_repository_impl.dart';
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
import 'package:islami/features/quran/presentation/pages/mushaf_reader_view.dart';

class _NoProgress implements QuranRepository {
  @override
  Future<Either<Failure, ReadingProgress?>> getProgress(int suraId) async =>
      const Right(null);
  @override
  Future<Either<Failure, Unit>> saveProgress(ReadingProgress p) async =>
      const Right(unit);
  @override
  Future<Either<Failure, Unit>> addRecentSura(int suraId) async =>
      const Right(unit);
  @override
  Future<Either<Failure, List<Sura>>> getAllSuras() async => const Right([]);
  @override
  Future<Either<Failure, List<Sura>>> getRecentSuras() async => const Right([]);
}

void main() {
  setUp(() {
    final mushaf = MushafRepositoryImpl(
      localDataSource: MushafLocalDataSourceImpl(),
    );
    final quran = _NoProgress();
    sl.registerFactory(
      () => MushafReaderBloc(
        getPage: GetPage(mushaf),
        getPageForAyah: GetPageForAyah(mushaf),
        getSuraInfo: GetSuraInfo(mushaf),
        getJuzStart: GetJuzStart(mushaf),
        getReadingProgress: GetReadingProgress(quran),
        saveReadingProgress: SaveReadingProgress(quran),
        addRecentSura: AddRecentSura(quran),
      ),
    );
  });

  tearDown(() => sl.reset());

  /// Lets asset loads (real async work) finish, then the frames after them.
  Future<void> settle(WidgetTester tester) async {
    // Pages decode on another isolate: give them real time, until no page
    // is still loading.
    for (var i = 0; i < 200; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    await tester.pumpAndSettle();
  }

  /// Opens the reader on [sura] and waits for its page to load.
  Future<void> open(WidgetTester tester, int sura) async {
    tester.view
      ..physicalSize = const Size(1200, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (_) => MaterialPageRoute(
          settings: RouteSettings(arguments: MushafReaderArgs(sura)),
          builder: (_) => const MushafReaderView(),
        ),
      ),
    );
    await settle(tester);
  }

  /// The page number under the page, in Arabic digits.
  Finder pageNumber(int page) => find.text(toArabicDigits(page));

  Offset centre(WidgetTester tester) => tester.getCenter(find.byType(PageView));

  testWidgets('a fast swipe to the right turns to the next page', (
    tester,
  ) async {
    await open(tester, 1);
    expect(pageNumber(1), findsOneWidget);

    // Right to left: the next page comes in from the left.
    await tester.flingFrom(centre(tester), const Offset(300, 0), 3000);
    await settle(tester);

    expect(pageNumber(2), findsOneWidget);
  });

  testWidgets('a sideways pinch zooms in and does not turn the page', (
    tester,
  ) async {
    await open(tester, 1);
    final c = centre(tester);

    final a = await tester.startGesture(c - const Offset(40, 0), pointer: 11);
    final b = await tester.startGesture(c + const Offset(40, 0), pointer: 12);
    for (var i = 0; i < 10; i++) {
      await a.moveBy(const Offset(-12, 0));
      await b.moveBy(const Offset(12, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await a.up();
    await b.up();
    await settle(tester);

    expect(pageNumber(1), findsOneWidget, reason: 'still on page 1');
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(1.5),
    );

    // Zoomed in, a swipe pans the page instead of turning it.
    await tester.flingFrom(centre(tester), const Offset(300, 0), 3000);
    await settle(tester);
    expect(pageNumber(1), findsOneWidget);
  });
}
