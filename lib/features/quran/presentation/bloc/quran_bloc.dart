import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/sura.dart';
import '../../domain/usecases/add_recent_sura.dart';
import '../../domain/usecases/get_all_suras.dart';
import '../../domain/usecases/get_recent_suras.dart';

part 'quran_event.dart';
part 'quran_state.dart';

class QuranBloc extends Bloc<QuranEvent, QuranState> {
  final GetAllSuras getAllSuras;
  final GetRecentSuras getRecentSuras;
  final AddRecentSura addRecentSura;

  QuranBloc({
    required this.getAllSuras,
    required this.getRecentSuras,
    required this.addRecentSura,
  }) : super(const QuranState()) {
    on<LoadSurasEvent>(_onLoadSuras);
    on<SearchSurasEvent>(_onSearchSuras);
    on<LoadRecentSurasEvent>(_onLoadRecentSuras);
    on<MarkSuraAsReadEvent>(_onMarkSuraAsRead);
  }

  Future<void> _onLoadSuras(
    LoadSurasEvent event,
    Emitter<QuranState> emit,
  ) async {
    emit(state.copyWith(status: QuranStatus.loading));
    final result = await getAllSuras(const NoParams());
    await result.fold(
      (failure) async => emit(state.copyWith(
        status: QuranStatus.failure,
        errorMessage: failure.message,
      )),
      (suras) async {
        emit(state.copyWith(
          status: QuranStatus.success,
          allSuras: suras,
          filteredSuras: suras,
        ));
        await _refreshRecents(emit);
      },
    );
  }

  Future<void> _onLoadRecentSuras(
    LoadRecentSurasEvent event,
    Emitter<QuranState> emit,
  ) async {
    await _refreshRecents(emit);
  }

  Future<void> _onMarkSuraAsRead(
    MarkSuraAsReadEvent event,
    Emitter<QuranState> emit,
  ) async {
    await addRecentSura(AddRecentSuraParams(event.sura.id));
    await _refreshRecents(emit);
  }

  void _onSearchSuras(
    SearchSurasEvent event,
    Emitter<QuranState> emit,
  ) {
    final raw = event.query.trim();
    final lower = raw.toLowerCase();
    final filtered = raw.isEmpty
        ? state.allSuras
        : state.allSuras
            .where((sura) =>
                sura.nameEn.toLowerCase().contains(lower) ||
                sura.nameAr.contains(raw))
            .toList();
    emit(state.copyWith(query: raw, filteredSuras: filtered));
  }

  /// Loads the recently read suras and merges them into the current state.
  Future<void> _refreshRecents(Emitter<QuranState> emit) async {
    final result = await getRecentSuras(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(recentSuras: const [])),
      (recent) => emit(state.copyWith(recentSuras: recent)),
    );
  }
}
