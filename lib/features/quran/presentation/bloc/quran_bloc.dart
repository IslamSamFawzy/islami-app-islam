import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/view_status.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/sura.dart';
import '../../domain/services/sura_search_filter.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/usecases/add_recent_sura.dart';
import '../../domain/usecases/get_all_suras.dart';
import '../../domain/usecases/get_reading_progress.dart';
import '../../domain/usecases/get_recent_suras.dart';

part 'quran_event.dart';
part 'quran_state.dart';

class QuranBloc extends Bloc<QuranEvent, QuranState> {
  final GetAllSuras getAllSuras;
  final GetRecentSuras getRecentSuras;
  final AddRecentSura addRecentSura;

  /// So a recent sura can say which ayah the reader stopped at.
  final GetReadingProgress getReadingProgress;

  final SuraSearchFilter suraSearchFilter;

  QuranBloc({
    required this.getAllSuras,
    required this.getRecentSuras,
    required this.addRecentSura,
    required this.getReadingProgress,
    required this.suraSearchFilter,
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
    emit(state.copyWith(status: ViewStatus.loading));
    final result = await getAllSuras(const NoParams());
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: ViewStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (suras) async {
        emit(
          state.copyWith(
            status: ViewStatus.success,
            allSuras: suras,
            filteredSuras: suras,
          ),
        );
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

  void _onSearchSuras(SearchSurasEvent event, Emitter<QuranState> emit) {
    final raw = event.query.trim();
    final filtered = suraSearchFilter.filter(state.allSuras, raw);
    emit(state.copyWith(query: raw, filteredSuras: filtered));
  }

  /// Loads the recently read suras, and how far the reader got in each, and
  /// merges them into the current state.
  Future<void> _refreshRecents(Emitter<QuranState> emit) async {
    final result = await getRecentSuras(const NoParams());
    final recent = result.fold((_) => const <Sura>[], (recent) => recent);

    emit(
      state.copyWith(
        recentSuras: recent,
        recentProgress: await _progressFor(recent),
      ),
    );
  }

  Future<Map<int, ReadingProgress>> _progressFor(List<Sura> suras) async {
    final found = await Future.wait(suras.map((s) => getReadingProgress(s.id)));
    // A sura that has never been read has no progress, and a failed read is
    // treated the same — the card simply won't offer to resume it.
    final progresses = [
      for (final result in found) result.getOrElse(() => null),
    ];
    return {for (final progress in progresses) ?progress?.suraId: ?progress};
  }
}
