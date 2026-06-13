import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/quran_repository.dart';

class AddRecentSura implements UseCase<Unit, AddRecentSuraParams> {
  final QuranRepository repository;

  AddRecentSura(this.repository);

  @override
  Future<Either<Failure, Unit>> call(AddRecentSuraParams params) {
    return repository.addRecentSura(params.suraId);
  }
}

class AddRecentSuraParams extends Equatable {
  final String suraId;

  const AddRecentSuraParams(this.suraId);

  @override
  List<Object?> get props => [suraId];
}
