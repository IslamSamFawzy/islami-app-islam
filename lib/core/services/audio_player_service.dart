import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:equatable/equatable.dart';

/// What the one app-wide player is on: the tag whoever started it supplied,
/// and whether it is playing rather than paused.
class AudioStatus extends Equatable {
  /// Empty when nothing is loaded.
  final String tag;

  final bool isPlaying;

  const AudioStatus({this.tag = '', this.isPlaying = false});

  @override
  List<Object?> get props => [tag, isPlaying];
}

/// App-wide audio playback (radio streams, reciters, online adhan).
///
/// There is one player, so there is one owner: every play call carries a [tag]
/// naming what is being played, and [status] tells anyone who asks whether the
/// audio is still theirs. The plugin's types stay behind this contract.
abstract class AudioPlayerService {
  /// Every change of what is loaded and whether it is playing.
  Stream<AudioStatus> get statusStream;

  /// What is loaded right now.
  AudioStatus get status;

  /// Whether audio is playing (as opposed to paused or stopped).
  bool get isPlaying;

  /// Stops any current audio and starts streaming [url] as [tag].
  Future<void> playUrl(String url, {required String tag});

  /// Stops any current audio and plays a local file as [tag] (works offline).
  Future<void> playFile(String path, {required String tag});

  Future<void> pause();

  Future<void> resume();

  /// Pauses what is playing, or resumes what is paused.
  Future<void> togglePause();

  /// Stops playback and gives up the tag.
  Future<void> stop();

  Future<void> dispose();
}

/// [AudioPlayerService] implementation backed by the audioplayers plugin.
class AudioPlayerServiceImpl implements AudioPlayerService {
  final AudioPlayer _player;

  // Synchronous so a screen sees the handover in the same turn it happens.
  final _statusController = StreamController<AudioStatus>.broadcast(sync: true);
  late final StreamSubscription<PlayerState> _playerSub;

  AudioStatus _status = const AudioStatus();

  AudioPlayerServiceImpl({AudioPlayer? player})
    : _player = player ?? AudioPlayer() {
    _playerSub = _player.onPlayerStateChanged.listen((state) {
      _emit(
        AudioStatus(tag: _status.tag, isPlaying: state == PlayerState.playing),
      );
    });
  }

  @override
  Stream<AudioStatus> get statusStream => _statusController.stream;

  @override
  AudioStatus get status => _status;

  @override
  bool get isPlaying => _player.state == PlayerState.playing;

  @override
  Future<void> playUrl(String url, {required String tag}) async {
    _takeOver(tag);
    await _player.stop();
    await _player.play(UrlSource(url));
  }

  @override
  Future<void> playFile(String path, {required String tag}) async {
    _takeOver(tag);
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> togglePause() => isPlaying ? pause() : resume();

  @override
  Future<void> stop() async {
    _emit(const AudioStatus());
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    await _playerSub.cancel();
    await _statusController.close();
    await _player.dispose();
  }

  /// Hands the player to [tag] before the source changes, so the screen that
  /// owned it sees the handover immediately.
  void _takeOver(String tag) =>
      _emit(AudioStatus(tag: tag, isPlaying: _status.isPlaying));

  void _emit(AudioStatus status) {
    if (status == _status) return;
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }
}
