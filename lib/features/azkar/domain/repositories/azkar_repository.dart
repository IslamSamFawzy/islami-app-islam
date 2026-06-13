import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/azkar.dart';

abstract class AzkarRepository {
  Future<Either<Failure, AzkarCollection>> getAzkar(AzkarType type);
}
