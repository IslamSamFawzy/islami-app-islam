part of 'quran_details_bloc.dart';

abstract class QuranDetailsEvent extends Equatable {
  const QuranDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the verses for the sura identified by [suraId]. With [resume] the
/// list opens where the reader left off instead of at the top.
class LoadVersesEvent extends QuranDetailsEvent {
  final int suraId;
  final bool resume;

  const LoadVersesEvent(this.suraId, {this.resume = false});

  @override
  List<Object?> get props => [suraId, resume];
}

/// Taps an ayah, which highlights it (or clears the highlight).
class SelectVerseEvent extends QuranDetailsEvent {
  final int index;

  const SelectVerseEvent(this.index);

  @override
  List<Object?> get props => [index];
}

/// The first fully visible ayah changed as the reader scrolled.
class VerseVisibleEvent extends QuranDetailsEvent {
  final int index;

  const VerseVisibleEvent(this.index);

  @override
  List<Object?> get props => [index];
}

/// Writes the position now rather than waiting out the debounce — used when
/// the app goes to the background.
class SaveProgressNowEvent extends QuranDetailsEvent {
  const SaveProgressNowEvent();
}

/// Internal: the resumed ayah has been highlighted long enough.
class _ClearHighlightEvent extends QuranDetailsEvent {
  const _ClearHighlightEvent();
}
