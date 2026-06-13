import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/quran_repository.dart';

class GetSuraVerses implements UseCase<List<String>, SuraVersesParams> {
  final QuranRepository repository;

  GetSuraVerses(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(SuraVersesParams params) {
    return repository.getSuraVerses(params.suraId);
  }
}

class SuraVersesParams extends Equatable {
  final String suraId;

  const SuraVersesParams(this.suraId);

  @override
  List<Object?> get props => [suraId];
}
