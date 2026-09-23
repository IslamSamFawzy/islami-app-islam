import 'package:dartz/dartz.dart';

import '../../../../core/data/guard.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/azkar.dart';
import '../../domain/repositories/azkar_repository.dart';
import '../datasources/azkar_local_data_source.dart';

class AzkarRepositoryImpl implements AzkarRepository {
  final AzkarLocalDataSource localDataSource;

  AzkarRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, AzkarCollection>> getAzkar(AzkarType type) {
    return guardLocalData(() => localDataSource.getAzkar(type));
  }
}
