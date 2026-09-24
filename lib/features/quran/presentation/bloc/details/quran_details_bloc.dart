import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/presentation/view_status.dart';
import '../../../domain/entities/reading_progress.dart';
import '../../../domain/usecases/get_reading_progress.dart';
import '../../../domain/usecases/get_sura_verses.dart';
import '../../../domain/usecases/save_reading_progress.dart';

part 'quran_details_event.dart';
part 'quran_details_state.dart';

class QuranDetailsBloc extends Bloc<QuranDetailsEvent, QuranDetailsState> {
  final GetSuraVerses getSuraVerses;
  final GetReadingProgress getReadingProgress;
  final SaveReadingProgress saveReadingProgress;

  /// How long the list must settle before the position is written. Scrolling
  /// reports a new ayah constantly; this is what keeps it to one write.
  static const Duration saveDebounce = Duration(milliseconds: 500);

  /// How long the resumed ayah stays highlighted.
  static const Duration highlightDuration = Duration(seconds: 2);

  int _suraId = 0;
  int? _unsavedIndex;
  Timer? _saveTimer;
  Timer? _highlightTimer;

  QuranDetailsBloc({
    required this.getSuraVerses,
    required this.getReadingProgress,
    required this.saveReadingProgress,
  }) : super(const QuranDetailsState()) {
    on<LoadVersesEvent>(_onLoadVerses);
    on<SelectVerseEvent>(_onSelectVerse);
    on<VerseVisibleEvent>(_onVerseVisible);
    on<SaveProgressNowEvent>(_onSaveProgressNow);
    on<_ClearHighlightEvent>(_onClearHighlight);
  }

  Future<void> _onLoadVerses(
    LoadVersesEvent event,
    Emitter<QuranDetailsState> emit,
  ) async {
    _suraId = event.suraId;
    emit(state.copyWith(status: ViewStatus.loading));

    final result = await getSuraVerses(SuraVersesParams(event.suraId));
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: ViewStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (verses) async {
        final resumeAt = event.resume ? await _savedIndex(verses.length) : -1;
        emit(
          state.copyWith(
            status: ViewStatus.success,
            verses: verses,
            initialIndex: resumeAt,
            // The ayah resumed at is highlighted, briefly, so the reader can
            // see where they were put.
            selectedIndex: resumeAt,
          ),
        );
        if (resumeAt >= 0) {
          _highlightTimer?.cancel();
          _highlightTimer = Timer(highlightDuration, () {
            if (!isClosed) add(const _ClearHighlightEvent());
          });
        }
      },
    );
  }

  void _onSelectVerse(SelectVerseEvent event, Emitter<QuranDetailsState> emit) {
    // Tapping the already-selected ayah clears the highlight.
    final next = state.selectedIndex == event.index ? -1 : event.index;
    emit(state.copyWith(selectedIndex: next));
  }

  void _onVerseVisible(
    VerseVisibleEvent event,
    Emitter<QuranDetailsState> emit,
  ) {
    if (event.index == _unsavedIndex) return;
    _unsavedIndex = event.index;
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDebounce, () {
      if (!isClosed) add(const SaveProgressNowEvent());
    });
  }

  Future<void> _onSaveProgressNow(
    SaveProgressNowEvent event,
    Emitter<QuranDetailsState> emit,
  ) {
    return _saveNow();
  }

  void _onClearHighlight(
    _ClearHighlightEvent event,
    Emitter<QuranDetailsState> emit,
  ) {
    emit(state.copyWith(selectedIndex: -1));
  }

  /// The saved ayah for this sura, or -1 when there is none (or the sura has
  /// since grown shorter than it).
  Future<int> _savedIndex(int verseCount) async {
    final result = await getReadingProgress(_suraId);
    final index = result.fold((_) => -1, (progress) => progress?.ayahIndex ?? -1);
    return index >= 0 && index < verseCount ? index : -1;
  }

  Future<void> _saveNow() async {
    final index = _unsavedIndex;
    _saveTimer?.cancel();
    if (index == null) return;
    _unsavedIndex = null;

    await saveReadingProgress(
      ReadingProgress(
        suraId: _suraId,
        ayahIndex: index,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> close() async {
    _highlightTimer?.cancel();
    // Leaving the screen counts as stopping there, debounce or not.
    await _saveNow();
    return super.close();
  }
}
