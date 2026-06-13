import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/radio_station.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/repositories/radio_repository.dart';
import '../datasources/radio_remote_data_source.dart';

class RadioRepositoryImpl implements RadioRepository {
  final RadioRemoteDataSource remoteDataSource;

  RadioRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<RadioStation>>> getRadios() async {
    try {
      final radios = await remoteDataSource.getRadios();
      return Right(radios);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Reciter>>> getReciters() async {
    try {
      final reciters = await remoteDataSource.getReciters();
      return Right(reciters);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
