import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/sura.dart';

/// Abstraction the presentation/domain layers depend on.
/// Implemented in the data layer.
abstract class QuranRepository {
  /// Returns the full list of 114 suras.
  Future<Either<Failure, List<Sura>>> getAllSuras();

  /// Returns the verses (ayat) of the sura identified by [suraId].
  Future<Either<Failure, List<String>>> getSuraVerses(String suraId);

  /// Returns the recently read suras, most recent first.
  Future<Either<Failure, List<Sura>>> getRecentSuras();

  /// Records the sura identified by [suraId] as recently read.
  Future<Either<Failure, Unit>> addRecentSura(String suraId);
}
