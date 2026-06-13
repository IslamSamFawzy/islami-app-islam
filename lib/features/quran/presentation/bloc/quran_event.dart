part of 'quran_bloc.dart';

abstract class QuranEvent extends Equatable {
  const QuranEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the full list of suras.
class LoadSurasEvent extends QuranEvent {
  const LoadSurasEvent();
}

/// Filters the loaded suras by [query] (English or Arabic name).
class SearchSurasEvent extends QuranEvent {
  final String query;

  const SearchSurasEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Reloads the list of recently read suras (e.g. after returning from details).
class LoadRecentSurasEvent extends QuranEvent {
  const LoadRecentSurasEvent();
}

/// Records [sura] as recently read and refreshes the recent list.
class MarkSuraAsReadEvent extends QuranEvent {
  final Sura sura;

  const MarkSuraAsReadEvent(this.sura);

  @override
  List<Object?> get props => [sura];
}
