import 'dart:async';

import 'package:equatable/equatable.dart';

import '../services/audio_player_service.dart';

/// What the player is on: the id its caller gave it, and whether that item is
/// playing rather than paused.
class PlaybackStatus extends Equatable {
  /// Empty when this controller has not started anything.
  final String currentId;

  final bool isPlaying;

  const PlaybackStatus({this.currentId = '', this.isPlaying = false});

  bool isCurrent(String id) => currentId.isNotEmpty && currentId == id;

  @override
  List<Object?> get props => [currentId, isPlaying];
}

/// The playback rules every audio screen shares: tapping the item that is
/// already loaded pauses it (and tapping again resumes), tapping a different
/// one starts that instead, and leaving the screen stops only the audio this
/// screen started.
///
/// Radio, the reciter sura list and Downloads each kept their own copy of
/// those rules, along with their own subscription to the player.
class PlaybackController {
  final AudioPlayerService audioPlayerService;

  // Synchronous so a bloc or cubit mirrors the change in the same turn it is
  // made — the row highlights the moment playback is asked for, not a
  // microtask later.
  final _statusController = StreamController<PlaybackStatus>.broadcast(
    sync: true,
  );
  late final StreamSubscription<bool> _playingSub;

  PlaybackStatus _status = const PlaybackStatus();

  PlaybackController({required this.audioPlayerService}) {
    _playingSub = audioPlayerService.isPlayingStream.listen((playing) {
      _emit(PlaybackStatus(currentId: _status.currentId, isPlaying: playing));
    });
  }

  /// Every change, for the caller to mirror into its own state.
  Stream<PlaybackStatus> get statusStream => _statusController.stream;

  PlaybackStatus get status => _status;

  bool isCurrent(String id) => _status.isCurrent(id);

  /// Pauses or resumes whatever is loaded.
  Future<void> togglePause() => audioPlayerService.togglePause();

  /// Makes [id] the current item, then runs [start] — the call that actually
  /// hands a URL or a file to the player.
  Future<void> play(String id, Future<void> Function() start) async {
    _emit(PlaybackStatus(currentId: id, isPlaying: _status.isPlaying));
    await start();
  }

  /// A tap on [id]: pause/resume when it is already current, start it
  /// otherwise.
  Future<void> toggle(String id, Future<void> Function() start) {
    return isCurrent(id) ? togglePause() : play(id, start);
  }

  /// Stops when the current item matches [test] — before deleting the file
  /// that is playing, say. Returns whether it stopped anything.
  Future<bool> stopWhere(bool Function(String id) test) async {
    if (_status.currentId.isEmpty || !test(_status.currentId)) return false;
    await audioPlayerService.stop();
    _emit(const PlaybackStatus());
    return true;
  }

  /// Drops the subscription and stops the audio **only if this controller
  /// started it**, so leaving a screen never cuts off playback owned elsewhere.
  Future<void> close() async {
    await _playingSub.cancel();
    if (_status.currentId.isNotEmpty) await audioPlayerService.stop();
    await _statusController.close();
  }

  void _emit(PlaybackStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }
}
