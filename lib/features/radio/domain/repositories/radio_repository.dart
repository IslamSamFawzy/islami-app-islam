import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/radio_station.dart';
import '../entities/reciter.dart';

abstract class RadioRepository {
  Future<Either<Failure, List<RadioStation>>> getRadios();

  Future<Either<Failure, List<Reciter>>> getReciters();
}
