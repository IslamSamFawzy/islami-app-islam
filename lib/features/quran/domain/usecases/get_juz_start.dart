import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/ayah.dart';
import '../repositories/mushaf_repository.dart';

/// The first ayah of juz `params`, 1-30.
class GetJuzStart implements UseCase<Ayah, int> {
  final MushafRepository repository;

  GetJuzStart(this.repository);

  @override
  Future<Either<Failure, Ayah>> call(int params) =>
      repository.getJuzStart(params);
}
