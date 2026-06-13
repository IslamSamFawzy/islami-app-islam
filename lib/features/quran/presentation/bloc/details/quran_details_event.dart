part of 'quran_details_bloc.dart';

abstract class QuranDetailsEvent extends Equatable {
  const QuranDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the verses for the sura identified by [suraId].
class LoadVersesEvent extends QuranDetailsEvent {
  final String suraId;

  const LoadVersesEvent(this.suraId);

  @override
  List<Object?> get props => [suraId];
}
