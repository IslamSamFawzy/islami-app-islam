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

/// Selects (or, if already selected, deselects) the ayah at [index] so it is
/// rendered filled gold with dark text — the "currently read" state (spec §2.4).
class SelectVerseEvent extends QuranDetailsEvent {
  final int index;

  const SelectVerseEvent(this.index);

  @override
  List<Object?> get props => [index];
}
