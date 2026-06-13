import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/azkar.dart';
import '../../domain/repositories/azkar_repository.dart';
import '../datasources/azkar_local_data_source.dart';

class AzkarRepositoryImpl implements AzkarRepository {
  final AzkarLocalDataSource localDataSource;

  AzkarRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, AzkarCollection>> getAzkar(AzkarType type) async {
    try {
      final collection = await localDataSource.getAzkar(type);
      return Right(collection);
    } on LocalDataException catch (e) {
      return Left(LocalDataFailure(e.message));
    }
  }
}
