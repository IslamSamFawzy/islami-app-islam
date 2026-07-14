import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/audio_player_service.dart';
import '../../../../core/usecase/params.dart';
import '../../domain/entities/radio_station.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/usecases/get_radios.dart';
import '../../domain/usecases/get_reciters.dart';

part 'radio_event.dart';
part 'radio_state.dart';

class RadioBloc extends Bloc<RadioEvent, RadioState> {
  final GetRadios getRadios;
  final GetReciters getReciters;
  final AudioPlayerService audioPlayerService;

  StreamSubscription<PlayerState>? _playerSub;

  RadioBloc({
    required this.getRadios,
    required this.getReciters,
    required this.audioPlayerService,
  }) : super(const RadioState()) {
    on<LoadRadioDataEvent>(_onLoad);
    on<_RefreshRadioDataEvent>(_onRefresh);
    on<SelectTabEvent>(_onSelectTab);
    on<PlayItemEvent>(_onPlayItem);
    on<_PlayerStateChangedEvent>(_onPlayerStateChanged);

    _playerSub = audioPlayerService.onStateChanged.listen((s) {
      if (!isClosed) {
        add(_PlayerStateChangedEvent(s == PlayerState.playing));
      }
    });
  }

  Future<void> _onLoad(
    LoadRadioDataEvent event,
    Emitter<RadioState> emit,
  ) async {
    emit(state.copyWith(status: RadioStatus.loading));

    // Phase 1 — prefer the cache; if none exists this falls through to the
    // network so first-time users still get data.
    final radiosResult = await getRadios(const RefreshParams());
    final recitersResult = await getReciters(const RefreshParams());

    final radios = radiosResult.fold((_) => <RadioStation>[], (r) => r.data);
    final reciters = recitersResult.fold((_) => <Reciter>[], (r) => r.data);
    final fromCache = radiosResult.fold((_) => false, (r) => r.fromCache) ||
        recitersResult.fold((_) => false, (r) => r.fromCache);

    if (radios.isEmpty && reciters.isEmpty) {
      emit(state.copyWith(
        status: RadioStatus.failure,
        errorMessage: 'Failed to load radio data. Check your connection.',
      ));
      return;
    }

    emit(state.copyWith(
      status: RadioStatus.success,
      radios: radios,
      reciters: reciters,
      isFromCache: fromCache,
    ));

    // Phase 2 — only worth refreshing if what we showed was cached.
    if (fromCache) add(const _RefreshRadioDataEvent());
  }

  Future<void> _onRefresh(
    _RefreshRadioDataEvent event,
    Emitter<RadioState> emit,
  ) async {
    final radiosResult = await getRadios(const RefreshParams(forceRefresh: true));
    final recitersResult =
        await getReciters(const RefreshParams(forceRefresh: true));

    // Keep whatever is currently shown if a fetch fails outright.
    final radios = radiosResult.fold((_) => state.radios, (r) => r.data);
    final reciters = recitersResult.fold((_) => state.reciters, (r) => r.data);
    final fromCache =
        radiosResult.fold((_) => state.isFromCache, (r) => r.fromCache) ||
            recitersResult.fold((_) => state.isFromCache, (r) => r.fromCache);

    // Equatable de-dupes: this only re-emits when the fresh data (or its
    // provenance) actually differs from what is on screen.
    emit(state.copyWith(
      status: RadioStatus.success,
      radios: radios,
      reciters: reciters,
      isFromCache: fromCache,
    ));
  }

  void _onSelectTab(SelectTabEvent event, Emitter<RadioState> emit) {
    emit(state.copyWith(tab: event.tab));
  }

  Future<void> _onPlayItem(
    PlayItemEvent event,
    Emitter<RadioState> emit,
  ) async {
    // Tapping the currently playing item toggles pause/resume.
    if (state.currentId == event.id) {
      if (state.isPlaying) {
        await audioPlayerService.pause();
      } else {
        await audioPlayerService.resume();
      }
      return;
    }
    emit(state.copyWith(currentId: event.id));
    await audioPlayerService.playUrl(event.url);
  }

  void _onPlayerStateChanged(
    _PlayerStateChangedEvent event,
    Emitter<RadioState> emit,
  ) {
    emit(state.copyWith(isPlaying: event.isPlaying));
  }

  @override
  Future<void> close() {
    _playerSub?.cancel();
    audioPlayerService.stop();
    return super.close();
  }
}
