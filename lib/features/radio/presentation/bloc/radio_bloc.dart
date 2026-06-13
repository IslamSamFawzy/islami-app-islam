import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/audio_player_service.dart';
import '../../../../core/usecase/usecase.dart';
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

    final radiosResult = await getRadios(const NoParams());
    final recitersResult = await getReciters(const NoParams());

    final radios = radiosResult.fold((_) => <RadioStation>[], (r) => r);
    final reciters = recitersResult.fold((_) => <Reciter>[], (r) => r);

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
