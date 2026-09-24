import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/reading_progress.dart';
import '../entities/sura.dart';

/// Abstraction the presentation/domain layers depend on.
/// Implemented in the data layer.
abstract class QuranRepository {
  /// Returns the full list of 114 suras.
  Future<Either<Failure, List<Sura>>> getAllSuras();

  /// Returns the verses (ayat) of the sura identified by [suraId].
  Future<Either<Failure, List<String>>> getSuraVerses(int suraId);

  /// Returns the recently read suras, most recent first.
  Future<Either<Failure, List<Sura>>> getRecentSuras();

  /// Records the sura identified by [suraId] as recently read.
  Future<Either<Failure, Unit>> addRecentSura(int suraId);

  /// Where the reader left off in [suraId], or `null` if they never have.
  Future<Either<Failure, ReadingProgress?>> getProgress(int suraId);

  /// Remembers where the reader is now.
  Future<Either<Failure, Unit>> saveProgress(ReadingProgress progress);
}
