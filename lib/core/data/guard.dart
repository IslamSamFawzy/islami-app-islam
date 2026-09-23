import 'package:dartz/dartz.dart';

import '../error/exceptions.dart';
import '../error/failures.dart';

/// Runs [read] and turns a [LocalDataException] into a [LocalDataFailure].
///
/// Every repository over a bundled-asset data source (azkar, hadith, quran)
/// wraps its calls the same way; this is that try/catch, written once.
Future<Either<Failure, T>> guardLocalData<T>(Future<T> Function() read) async {
  try {
    return Right(await read());
  } on LocalDataException catch (e) {
    return Left(LocalDataFailure(e.message));
  }
}
