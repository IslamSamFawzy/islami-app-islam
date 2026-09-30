import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/ayah.dart';
import '../entities/mushaf_page.dart';
import '../entities/sura_info.dart';

/// The Madinah Mushaf: 604 pages of the KFGQPC Hafs text.
abstract class MushafRepository {
  /// Page [number], 1-604.
  Future<Either<Failure, MushafPage>> getPage(int number);

  /// Ayah [number] of [sura]: its page, juz, hizb and sajdah.
  Future<Either<Failure, Ayah>> getAyah(int sura, int number);

  /// Where sura [number] is in the Mushaf.
  Future<Either<Failure, SuraInfo>> getSuraInfo(int number);

  /// The first ayah of juz [number], 1-30.
  Future<Either<Failure, Ayah>> getJuzStart(int number);

  /// The exact text of an ayah, with its ayah-end marker, for sharing and
  /// search.
  Future<Either<Failure, String>> getAyahText(int sura, int number);
}
