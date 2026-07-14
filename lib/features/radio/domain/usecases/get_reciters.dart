import 'package:dartz/dartz.dart';

import '../../../../core/cache/cache_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/params.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/reciter.dart';
import '../repositories/radio_repository.dart';

class GetReciters
    implements UseCase<CacheResult<List<Reciter>>, RefreshParams> {
  final RadioRepository repository;

  GetReciters(this.repository);

  @override
  Future<Either<Failure, CacheResult<List<Reciter>>>> call(
    RefreshParams params,
  ) {
    return repository.getReciters(forceRefresh: params.forceRefresh);
  }
}
