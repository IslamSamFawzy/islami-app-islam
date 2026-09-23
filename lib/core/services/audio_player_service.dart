import 'package:audioplayers/audioplayers.dart';

/// App-wide audio playback (radio streams, reciters, online adhan).
///
/// The plugin's types stay behind this contract: callers get a bool, not
/// audioplayers' `PlayerState`.
abstract class AudioPlayerService {
  /// Emits true when audio starts playing and false when it pauses, stops or
  /// reaches the end.
  Stream<bool> get isPlayingStream;

  /// Whether audio is playing right now (as opposed to paused or stopped).
  bool get isPlaying;

  /// Stops any current audio and starts streaming [url].
  Future<void> playUrl(String url);

  /// Stops any current audio and plays a local file (works offline).
  Future<void> playFile(String path);

  Future<void> pause();

  Future<void> resume();

  /// Pauses what is playing, or resumes what is paused.
  Future<void> togglePause();

  Future<void> stop();

  Future<void> dispose();
}

/// [AudioPlayerService] implementation backed by the audioplayers plugin.
class AudioPlayerServiceImpl implements AudioPlayerService {
  final AudioPlayer _player;

  AudioPlayerServiceImpl({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  @override
  Stream<bool> get isPlayingStream =>
      _player.onPlayerStateChanged.map((s) => s == PlayerState.playing);

  @override
  bool get isPlaying => _player.state == PlayerState.playing;

  @override
  Future<void> playUrl(String url) async {
    await _player.stop();
    await _player.play(UrlSource(url));
  }

  @override
  Future<void> playFile(String path) async {
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
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
