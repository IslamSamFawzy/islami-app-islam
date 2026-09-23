import 'package:audioplayers/audioplayers.dart';

/// App-wide audio playback (radio streams, reciters, online adhan).
abstract class AudioPlayerService {
  /// Emits play/pause/stop/complete transitions.
  Stream<PlayerState> get onStateChanged;

  /// The current player state, for snapshots.
  PlayerState get state;

  /// Stops any current audio and starts streaming [url].
  Future<void> playUrl(String url);

  /// Stops any current audio and plays a local file (works offline).
  Future<void> playFile(String path);

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  Future<void> dispose();
}

/// [AudioPlayerService] implementation backed by the audioplayers plugin.
class AudioPlayerServiceImpl implements AudioPlayerService {
  final AudioPlayer _player;

  AudioPlayerServiceImpl({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  @override
  Stream<PlayerState> get onStateChanged => _player.onPlayerStateChanged;

  @override
  PlayerState get state => _player.state;

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
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
