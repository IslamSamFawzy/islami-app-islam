import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/get_sura_verses.dart';

part 'quran_details_event.dart';
part 'quran_details_state.dart';

class QuranDetailsBloc extends Bloc<QuranDetailsEvent, QuranDetailsState> {
  final GetSuraVerses getSuraVerses;

  QuranDetailsBloc({required this.getSuraVerses})
      : super(const QuranDetailsState()) {
    on<LoadVersesEvent>(_onLoadVerses);
    on<SelectVerseEvent>(_onSelectVerse);
  }

  void _onSelectVerse(SelectVerseEvent event, Emitter<QuranDetailsState> emit) {
    // Tapping the already-selected ayah clears the highlight.
    final next = state.selectedIndex == event.index ? -1 : event.index;
    emit(state.copyWith(selectedIndex: next));
  }

  Future<void> _onLoadVerses(
    LoadVersesEvent event,
    Emitter<QuranDetailsState> emit,
  ) async {
    emit(state.copyWith(status: DetailsStatus.loading));
    final result = await getSuraVerses(SuraVersesParams(event.suraId));
    result.fold(
      (failure) => emit(state.copyWith(
        status: DetailsStatus.failure,
        errorMessage: failure.message,
      )),
      (verses) => emit(state.copyWith(
        status: DetailsStatus.success,
        verses: verses,
      )),
    );
  }
}
