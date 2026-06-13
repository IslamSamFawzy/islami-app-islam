import 'package:audioplayers/audioplayers.dart';

/// App-wide audio playback (radio streams, reciters, online adhan).
/// A single underlying player so starting new audio replaces the old.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  /// Emits play/pause/stop/complete transitions.
  Stream<PlayerState> get onStateChanged => _player.onPlayerStateChanged;

  PlayerState get state => _player.state;

  /// Stops any current audio and starts streaming [url].
  Future<void> playUrl(String url) async {
    await _player.stop();
    await _player.play(UrlSource(url));
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() => _player.resume();

  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.dispose();
}
