import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/ayah_ref.dart';
import '../repositories/mushaf_repository.dart';

/// The exact text of an ayah, for sharing and search.
class GetAyahText implements UseCase<String, AyahRef> {
  final MushafRepository repository;

  GetAyahText(this.repository);

  @override
  Future<Either<Failure, String>> call(AyahRef params) =>
      repository.getAyahText(params.sura, params.ayah);
}
