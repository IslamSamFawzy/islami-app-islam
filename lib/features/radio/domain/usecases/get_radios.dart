import 'package:dartz/dartz.dart';

import '../../../../core/cache/cache_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/params.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/radio_station.dart';
import '../repositories/radio_repository.dart';

class GetRadios
    implements UseCase<CacheResult<List<RadioStation>>, RefreshParams> {
  final RadioRepository repository;

  GetRadios(this.repository);

  @override
  Future<Either<Failure, CacheResult<List<RadioStation>>>> call(
    RefreshParams params,
  ) {
    return repository.getRadios(forceRefresh: params.forceRefresh);
  }
}
