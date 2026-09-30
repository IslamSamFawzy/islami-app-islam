import 'package:dartz/dartz.dart';

import '../../../../core/data/guard.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/mushaf_page.dart';
import '../../domain/entities/sura_info.dart';
import '../../domain/repositories/mushaf_repository.dart';
import '../datasources/mushaf_local_data_source.dart';
import '../models/mushaf_models.dart';

class MushafRepositoryImpl implements MushafRepository {
  final MushafLocalDataSource localDataSource;

  MushafRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, MushafPage>> getPage(int number) {
    return guardLocalData(() async {
      final meta = await localDataSource.getMeta();
      final lines = await localDataSource.getPageLines(number);
      final first = lines.whereType<AyahLine>().expand((l) => l.words).first;
      final ayah = _ayah(meta, first.sura, first.ayah);
      return MushafPage(
        number: number,
        lines: lines,
        juz: ayah.juz,
        hizb: ayah.hizb,
        quarter: ayah.quarter,
      );
    });
  }

  @override
  Future<Either<Failure, Ayah>> getAyah(int sura, int number) {
    return guardLocalData(
      () async => _ayah(await localDataSource.getMeta(), sura, number),
    );
  }

  @override
  Future<Either<Failure, SuraInfo>> getSuraInfo(int number) {
    return guardLocalData(() async {
      final meta = await localDataSource.getMeta();
      if (number < 1 || number > meta.suras.length) {
        throw LocalDataException('No sura $number');
      }
      return meta.suras[number - 1];
    });
  }

  @override
  Future<Either<Failure, Ayah>> getJuzStart(int number) {
    return guardLocalData(() async {
      final meta = await localDataSource.getMeta();
      if (number < 1 || number > meta.juzStarts.length) {
        throw LocalDataException('No juz $number');
      }
      final start = meta.juzStarts[number - 1];
      return _ayah(meta, start[0], start[1]);
    });
  }

  @override
  Future<Either<Failure, String>> getAyahText(int sura, int number) {
    return guardLocalData(() async {
      final meta = await localDataSource.getMeta();
      final text = StringBuffer();
      // An ayah can run onto the next page; read on until its marker.
      for (var page = _ayah(meta, sura, number).page; page <= 604; page++) {
        final lines = await localDataSource.getPageLines(page);
        for (final word in lines.whereType<AyahLine>().expand((l) => l.words)) {
          if (word.sura != sura || word.ayah != number) continue;
          text
            ..write(word.text)
            ..write(word.separator);
          if (word.kind == MushafWordKind.ayahEnd) return text.toString();
        }
      }
      throw LocalDataException('Ayah $sura:$number has no end');
    });
  }

  Ayah _ayah(MushafMetaModel meta, int sura, int number) {
    if (sura < 1 || sura > meta.ayahs.length) {
      throw LocalDataException('No sura $sura');
    }
    final ayat = meta.ayahs[sura - 1];
    if (number < 1 || number > ayat.length) {
      throw LocalDataException('No ayah $sura:$number');
    }
    return ayat[number - 1];
  }
}
