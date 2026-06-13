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
