import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/presentation/playback_controller.dart';
import 'package:islami/core/services/audio_player_service.dart';

/// Behaves like the real service: one tag at a time, and starting something
/// new takes the player over from whoever had it.
class _FakeAudio implements AudioPlayerService {
  final _controller = StreamController<AudioStatus>.broadcast(sync: true);
  final List<String> played = [];
  AudioStatus _status = const AudioStatus();
  int pauses = 0;
  int resumes = 0;
  int stops = 0;

  @override
  Stream<AudioStatus> get statusStream => _controller.stream;
  @override
  AudioStatus get status => _status;
  @override
  bool get isPlaying => _status.isPlaying;

  @override
  Future<void> playUrl(String url, {required String tag}) async {
    played.add(url);
    _emit(AudioStatus(tag: tag, isPlaying: true));
  }

  @override
  Future<void> playFile(String path, {required String tag}) async {
    played.add(path);
    _emit(AudioStatus(tag: tag, isPlaying: true));
  }

  @override
  Future<void> pause() async {
    pauses++;
    _emit(AudioStatus(tag: _status.tag));
  }

  @override
  Future<void> resume() async {
    resumes++;
    _emit(AudioStatus(tag: _status.tag, isPlaying: true));
  }

  @override
  Future<void> togglePause() => isPlaying ? pause() : resume();

  @override
  Future<void> stop() async {
    stops++;
    _emit(const AudioStatus());
  }

  @override
  Future<void> dispose() async => _controller.close();

  void _emit(AudioStatus status) {
    _status = status;
    _controller.add(status);
  }
}

void main() {
  late _FakeAudio audio;
  late PlaybackController controller;

  setUp(() {
    audio = _FakeAudio();
    controller = PlaybackController(
      audioPlayerService: audio,
      owner: 'radio',
    );
  });

  test('starting an item makes it this screen\'s current one', () async {
    await controller.toggleUrl(id: 'radio_1', url: 'stream');

    expect(audio.played, ['stream']);
    expect(controller.isCurrent('radio_1'), isTrue);
    expect(controller.status.currentId, 'radio_1');
    expect(controller.status.isPlaying, isTrue);
  });

  test('tapping the current item pauses it, then resumes it', () async {
    await controller.toggleUrl(id: 'radio_1', url: 'stream');

    await controller.toggleUrl(id: 'radio_1', url: 'stream');
    expect(audio.pauses, 1);
    expect(audio.played, ['stream'], reason: 'must not restart the stream');

    await controller.toggleUrl(id: 'radio_1', url: 'stream');
    expect(audio.resumes, 1);
  });

  test('tapping a different item starts that one instead', () async {
    await controller.toggleUrl(id: 'radio_1', url: 'one');
    await controller.toggleUrl(id: 'radio_2', url: 'two');

    expect(audio.played, ['one', 'two']);
    expect(controller.status.currentId, 'radio_2');
  });

  test('the status stream follows the player', () async {
    final seen = <PlaybackStatus>[];
    controller.statusStream.listen(seen.add);

    await controller.toggleUrl(id: '1', url: 'stream');
    await controller.togglePause();

    expect(seen.map((s) => s.currentId), ['1', '1']);
    expect(seen.map((s) => s.isPlaying), [true, false]);
  });

  test('stopWhere only stops a matching item', () async {
    await controller.toggleFile(id: '1/2', path: 'file');

    expect(await controller.stopWhere((id) => id == '9/9'), isFalse);
    expect(audio.stops, 0);

    expect(await controller.stopWhere((id) => id == '1/2'), isTrue);
    expect(audio.stops, 1);
    expect(controller.status.currentId, isEmpty);
  });

  test('close stops the audio only when this screen still owns it', () async {
    await controller.close();
    expect(audio.stops, 0);

    await controller.toggleUrl(id: 'radio_1', url: 'stream');
    await controller.close();
    expect(audio.stops, 1);
  });

  group('two screens sharing the one player', twoScreensGroup);
}

// The bug this design exists to prevent: one player, two screens.
void twoScreensGroup() {
  late _FakeAudio audio;
  late PlaybackController radio;
  late PlaybackController reciter;

  setUp(() {
    audio = _FakeAudio();
    radio = PlaybackController(audioPlayerService: audio, owner: 'radio');
    reciter = PlaybackController(
      audioPlayerService: audio,
      owner: 'reciter_1',
    );
  });

  test('a screen stops claiming the player once another takes it', () async {
    await radio.toggleUrl(id: 'radio_1', url: 'stream');
    expect(radio.status.isPlaying, isTrue);

    // Open a reciter and play a sura: same player, new owner.
    await reciter.toggleFile(id: '2', path: '/audio/1/2.mp3');

    expect(reciter.status.currentId, '2');
    expect(reciter.status.isPlaying, isTrue);
    // Going back to Radio must not show the station as still playing.
    expect(radio.status.currentId, isEmpty);
    expect(radio.status.isPlaying, isFalse);
    expect(radio.isCurrent('radio_1'), isFalse);
  });

  test('closing a screen never stops audio another one started', () async {
    await radio.toggleUrl(id: 'radio_1', url: 'stream');
    await reciter.toggleFile(id: '2', path: '/audio/1/2.mp3');

    // Radio's bloc is closed while the sura plays.
    await radio.close();
    expect(audio.stops, 0);
    expect(reciter.status.currentId, '2');

    await reciter.close();
    expect(audio.stops, 1);
  });

  test('the loser of a handover reports it through its stream', () async {
    final seen = <PlaybackStatus>[];
    radio.statusStream.listen(seen.add);

    await radio.toggleUrl(id: 'radio_1', url: 'stream');
    await reciter.toggleFile(id: '2', path: '/audio/1/2.mp3');

    expect(seen.last.currentId, isEmpty);
    expect(seen.last.isPlaying, isFalse);
  });
}
