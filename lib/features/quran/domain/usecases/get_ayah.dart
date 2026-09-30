import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/ayah.dart';
import '../entities/ayah_ref.dart';
import '../repositories/mushaf_repository.dart';

/// Where an ayah is: page, juz, hizb, sajdah.
class GetAyah implements UseCase<Ayah, AyahRef> {
  final MushafRepository repository;

  GetAyah(this.repository);

  @override
  Future<Either<Failure, Ayah>> call(AyahRef params) =>
      repository.getAyah(params.sura, params.ayah);
}
