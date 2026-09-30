import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/ayah_ref.dart';
import '../repositories/mushaf_repository.dart';

/// The page an ayah starts on.
class GetPageForAyah implements UseCase<int, AyahRef> {
  final MushafRepository repository;

  GetPageForAyah(this.repository);

  @override
  Future<Either<Failure, int>> call(AyahRef params) async =>
      (await repository.getAyah(params.sura, params.ayah)).map((a) => a.page);
}
