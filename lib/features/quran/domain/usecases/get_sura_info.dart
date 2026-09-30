import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/sura_info.dart';
import '../repositories/mushaf_repository.dart';

/// Where sura `params` is in the Mushaf.
class GetSuraInfo implements UseCase<SuraInfo, int> {
  final MushafRepository repository;

  GetSuraInfo(this.repository);

  @override
  Future<Either<Failure, SuraInfo>> call(int params) =>
      repository.getSuraInfo(params);
}
