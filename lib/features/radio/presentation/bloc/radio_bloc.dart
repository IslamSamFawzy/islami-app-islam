import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/playback_controller.dart';
import '../../../../core/presentation/view_status.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/usecase/params.dart';
import '../../../../core/utils/arabic_search.dart';
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
  final ConnectivityService connectivityService;

  late final PlaybackController _playback;
  StreamSubscription<PlaybackStatus>? _playbackSub;
  StreamSubscription<bool>? _connectivitySub;

  RadioBloc({
    required this.getRadios,
    required this.getReciters,
    required this.audioPlayerService,
    required this.connectivityService,
  }) : super(const RadioState()) {
    on<LoadRadioDataEvent>(_onLoad);
    on<_RefreshRadioDataEvent>(_onRefresh);
    on<_ConnectivityChangedEvent>(_onConnectivityChanged);
    on<SelectTabEvent>(_onSelectTab);
    on<SearchRadioEvent>(_onSearch);
    on<PlayItemEvent>(_onPlayItem);
    on<_PlaybackChangedEvent>(_onPlaybackChanged);

    _playback = PlaybackController(audioPlayerService: audioPlayerService);
    _playbackSub = _playback.statusStream.listen((status) {
      if (!isClosed) add(_PlaybackChangedEvent(status));
    });

    _connectivitySub = connectivityService.onConnectivityChanged.listen((online) {
      if (!isClosed) add(_ConnectivityChangedEvent(online));
    });
  }

  Future<void> _onLoad(
    LoadRadioDataEvent event,
    Emitter<RadioState> emit,
  ) async {
    emit(state.copyWith(status: ViewStatus.loading));

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
        status: ViewStatus.failure,
        errorMessage: 'Failed to load radio data. Check your connection.',
      ));
      return;
    }

    emit(state.copyWith(
      status: ViewStatus.success,
      radios: radios,
      reciters: reciters,
      isFromCache: fromCache,
      // Seed the offline flag so a cold start with no connection shows the
      // strip immediately (the stream only fires on subsequent changes).
      isOffline: !await connectivityService.isConnected,
    ));

    // Phase 2 — only worth refreshing if what we showed was cached.
    if (fromCache) add(const _RefreshRadioDataEvent());
  }

  Future<void> _onConnectivityChanged(
    _ConnectivityChangedEvent event,
    Emitter<RadioState> emit,
  ) async {
    emit(state.copyWith(isOffline: !event.online));
    if (!event.online) return;

    // Back online: retry a failed load, otherwise refresh in the background.
    if (state.status == ViewStatus.failure) {
      add(const LoadRadioDataEvent());
    } else {
      add(const _RefreshRadioDataEvent());
    }
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
      status: ViewStatus.success,
      radios: radios,
      reciters: reciters,
      isFromCache: fromCache,
    ));
  }

  void _onSelectTab(SelectTabEvent event, Emitter<RadioState> emit) {
    // Clear the query on tab switch so a stale filter never carries over.
    emit(state.copyWith(tab: event.tab, query: ''));
  }

  void _onSearch(SearchRadioEvent event, Emitter<RadioState> emit) {
    emit(state.copyWith(query: event.query));
  }

  Future<void> _onPlayItem(
    PlayItemEvent event,
    Emitter<RadioState> emit,
  ) async {
    // Tapping the currently playing item toggles pause/resume.
    if (_playback.isCurrent(event.id)) {
      await _playback.togglePause();
      return;
    }
    // Live streams are online-only; say so instead of failing silently.
    if (state.isOffline) {
      emit(state.copyWith(
        notice: 'Live radio needs an internet connection.',
        noticeSeq: state.noticeSeq + 1,
      ));
      return;
    }
    // Highlight the row now; the controller reports the same id straight back
    // through _PlaybackChangedEvent, which Equatable de-dupes.
    emit(state.copyWith(currentId: event.id));
    await _playback.play(event.id, () => audioPlayerService.playUrl(event.url));
  }

  void _onPlaybackChanged(
    _PlaybackChangedEvent event,
    Emitter<RadioState> emit,
  ) {
    emit(state.copyWith(
      currentId: event.status.currentId,
      isPlaying: event.status.isPlaying,
    ));
  }

  @override
  Future<void> close() {
    _playbackSub?.cancel();
    _connectivitySub?.cancel();
    // Stops the audio only if this bloc started it, so closing the Radio tab
    // never cuts off a sura playing from another screen.
    _playback.close();
    return super.close();
  }
}
