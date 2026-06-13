import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/hadith.dart';
import '../../domain/repositories/hadith_repository.dart';
import '../datasources/hadith_local_data_source.dart';

class HadithRepositoryImpl implements HadithRepository {
  final HadithLocalDataSource localDataSource;

  HadithRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Hadith>>> getAllHadiths() async {
    try {
      final hadiths = await localDataSource.getAllHadiths();
      return Right(hadiths);
    } on LocalDataException catch (e) {
      return Left(LocalDataFailure(e.message));
    }
  }
}
