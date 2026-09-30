import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/mushaf_page.dart';
import '../repositories/mushaf_repository.dart';

/// Loads Mushaf page `params`, 1-604.
class GetPage implements UseCase<MushafPage, int> {
  final MushafRepository repository;

  GetPage(this.repository);

  @override
  Future<Either<Failure, MushafPage>> call(int params) =>
      repository.getPage(params);
}
