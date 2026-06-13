part of 'hadith_bloc.dart';

abstract class HadithEvent extends Equatable {
  const HadithEvent();

  @override
  List<Object?> get props => [];
}

class LoadHadithsEvent extends HadithEvent {
  const LoadHadithsEvent();
}
