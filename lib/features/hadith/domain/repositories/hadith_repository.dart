import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/hadith.dart';

abstract class HadithRepository {
  Future<Either<Failure, List<Hadith>>> getAllHadiths();
}
