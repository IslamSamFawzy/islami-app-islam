import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/error/failures.dart';
import 'package:islami/features/quran/domain/entities/reading_progress.dart';
import 'package:islami/features/quran/domain/entities/sura.dart';
import 'package:islami/features/quran/domain/repositories/quran_repository.dart';
import 'package:islami/features/quran/domain/services/sura_search_filter.dart';
import 'package:islami/features/quran/domain/usecases/add_recent_sura.dart';
import 'package:islami/features/quran/domain/usecases/get_all_suras.dart';
import 'package:islami/features/quran/domain/usecases/get_reading_progress.dart';
import 'package:islami/features/quran/domain/usecases/get_recent_suras.dart';
import 'package:islami/features/quran/presentation/bloc/quran_bloc.dart';
import 'package:islami/features/quran/presentation/pages/mushaf_reader_view.dart';
import 'package:islami/features/quran/presentation/widgets/sura_item.dart';

const _baqarah = Sura(
  id: 2,
  nameEn: 'Al-Baqarah',
  nameAr: 'البقرة',
  ayaCount: 286,
);

class _Repository implements QuranRepository {
  @override
  Future<Either<Failure, List<Sura>>> getAllSuras() async =>
      const Right([_baqarah]);
  @override
  Future<Either<Failure, List<Sura>>> getRecentSuras() async => const Right([]);
  @override
  Future<Either<Failure, Unit>> addRecentSura(int suraId) async =>
      const Right(unit);
  @override
  Future<Either<Failure, ReadingProgress?>> getProgress(int suraId) async =>
      const Right(null);
  @override
  Future<Either<Failure, Unit>> saveProgress(ReadingProgress p) async =>
      const Right(unit);
}

void main() {
  testWidgets('a tap anywhere on the row opens the sura, even between the '
      'names', (tester) async {
    final repo = _Repository();
    final opened = <MushafReaderArgs>[];
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => QuranBloc(
          getAllSuras: GetAllSuras(repo),
          getRecentSuras: GetRecentSuras(repo),
          addRecentSura: AddRecentSura(repo),
          getReadingProgress: GetReadingProgress(repo),
          suraSearchFilter: DefaultSuraSearchFilter(),
        ),
        child: MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == MushafReaderView.routeName) {
              opened.add(settings.arguments! as MushafReaderArgs);
              return MaterialPageRoute(builder: (_) => const Text('reader'));
            }
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: SuraItem(sura: _baqarah)),
            );
          },
        ),
      ),
    );

    // Between the end of "286 Verses" and the Arabic name: no text there.
    final row = tester.getRect(find.byType(SuraItem));
    final verses = tester.getRect(find.text('286 Verses'));
    final arabic = tester.getRect(find.text('البقرة'));
    final gap = Offset((verses.right + arabic.left) / 2, row.center.dy);
    expect(gap.dx, greaterThan(verses.right));
    expect(gap.dx, lessThan(arabic.left));

    await tester.tapAt(gap);
    await tester.pumpAndSettle();

    expect(opened.single.sura, 2);
    expect(find.text('reader'), findsOneWidget);
  });
}
