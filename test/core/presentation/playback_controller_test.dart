import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/presentation/playback_controller.dart';
import 'package:islami/core/services/audio_player_service.dart';

class _FakeAudio implements AudioPlayerService {
  final _controller = StreamController<bool>.broadcast();
  bool _playing = false;
  int pauses = 0;
  int resumes = 0;
  int stops = 0;

  @override
  Stream<bool> get isPlayingStream => _controller.stream;
  @override
  bool get isPlaying => _playing;
  @override
  Future<void> playUrl(String url) async {}
  @override
  Future<void> playFile(String path) async {}
  @override
  Future<void> pause() async => pauses++;
  @override
  Future<void> resume() async => resumes++;
  @override
  Future<void> togglePause() => isPlaying ? pause() : resume();
  @override
  Future<void> stop() async => stops++;
  @override
  Future<void> dispose() async => _controller.close();

  void emitPlaying(bool playing) {
    _playing = playing;
    _controller.add(playing);
  }
}

void main() {
  late _FakeAudio audio;
  late PlaybackController controller;

  setUp(() {
    audio = _FakeAudio();
    controller = PlaybackController(audioPlayerService: audio);
  });

  test('play marks the item current and runs the starter', () async {
    var started = 0;

    await controller.play('radio_1', () async => started++);

    expect(started, 1);
    expect(controller.status.currentId, 'radio_1');
    expect(controller.isCurrent('radio_1'), isTrue);
  });

  test('toggle pauses the current item instead of restarting it', () async {
    var started = 0;
    await controller.toggle('radio_1', () async => started++);
    audio.emitPlaying(true);

    await controller.toggle('radio_1', () async => started++);

    expect(started, 1, reason: 'the same item must not start twice');
    expect(audio.pauses, 1);

    audio.emitPlaying(false);
    await controller.toggle('radio_1', () async => started++);
    expect(audio.resumes, 1);
  });

  test('toggle on a different item starts that one', () async {
    final started = <String>[];
    await controller.toggle('radio_1', () async => started.add('radio_1'));
    await controller.toggle('radio_2', () async => started.add('radio_2'));

    expect(started, ['radio_1', 'radio_2']);
    expect(controller.status.currentId, 'radio_2');
  });

  test('the status stream reports what the player is doing', () async {
    final seen = <PlaybackStatus>[];
    controller.statusStream.listen(seen.add);

    await controller.play('1', () async {});
    audio.emitPlaying(true);
    audio.emitPlaying(false);
    // The player's own stream is asynchronous; let it reach the controller.
    await pumpEventQueue();

    expect(seen.map((s) => s.currentId), ['1', '1', '1']);
    expect(seen.map((s) => s.isPlaying), [false, true, false]);
  });

  test('stopWhere only stops a matching item', () async {
    await controller.play('1/2', () async {});

    expect(await controller.stopWhere((id) => id == '9/9'), isFalse);
    expect(audio.stops, 0);

    expect(await controller.stopWhere((id) => id == '1/2'), isTrue);
    expect(audio.stops, 1);
    expect(controller.status.currentId, isEmpty);
  });

  test('close stops the audio only when this controller started it', () async {
    await controller.close();
    expect(audio.stops, 0);

    final owner = PlaybackController(audioPlayerService: audio);
    await owner.play('1', () async {});
    await owner.close();
    expect(audio.stops, 1);
  });
}
