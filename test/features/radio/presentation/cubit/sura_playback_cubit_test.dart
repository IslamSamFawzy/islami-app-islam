import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/services/audio_player_service.dart';
import 'package:islami/core/services/connectivity_service.dart';
import 'package:islami/features/downloads/data/datasources/downloads_local_data_source.dart';
import 'package:islami/features/downloads/data/models/download_entry_model.dart';
import 'package:islami/features/radio/domain/entities/reciter.dart';
import 'package:islami/features/radio/presentation/cubit/sura_playback_cubit.dart';

class _FakeAudio implements AudioPlayerService {
  String? playedFile;
  String? playedUrl;

  @override
  Stream<PlayerState> get onStateChanged => const Stream.empty();

  @override
  PlayerState get state => PlayerState.stopped;

  @override
  AudioPlayer get player => throw UnimplementedError();

  @override
  Future<void> playFile(String path) async => playedFile = path;

  @override
  Future<void> playUrl(String url) async => playedUrl = url;

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _FakeLocal implements DownloadsLocalDataSource {
  DownloadEntryModel? entry;

  @override
  DownloadEntryModel? get(String reciterId, String suraId) => entry;

  @override
  List<DownloadEntryModel> getAll() => entry == null ? [] : [entry!];

  @override
  Future<void> put(DownloadEntryModel e) async {}

  @override
  Future<void> remove(String reciterId, String suraId) async {}

  @override
  Future<void> removeReciter(String reciterId) async {}
}

class _FakeConnectivity implements ConnectivityService {
  bool connected;

  _FakeConnectivity(this.connected);

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

void main() {
  const reciter = Reciter(
    id: 1,
    name: 'Reciter',
    moshafServer: 'https://server/',
    surahList: [2, 3],
  );

  late _FakeAudio audio;
  late _FakeLocal local;

  SuraPlaybackCubit build(bool connected) => SuraPlaybackCubit(
        reciter: reciter,
        audioPlayerService: audio,
        downloadsLocalDataSource: local,
        connectivityService: _FakeConnectivity(connected),
      );

  setUp(() {
    audio = _FakeAudio();
    local = _FakeLocal();
  });

  test('plays the local file when the sura is downloaded', () async {
    final dir = await Directory.systemTemp.createTemp('sura_test');
    final file = File('${dir.path}/2.mp3');
    await file.writeAsString('audio');
    local.entry = DownloadEntryModel(
      reciterId: '1',
      reciterName: 'Reciter',
      suraId: '2',
      path: file.path,
      bytes: 5,
      downloadedAt: DateTime(2026),
    );

    final cubit = build(false); // offline, but the file is local
    await cubit.toggle(2);

    expect(audio.playedFile, file.path);
    expect(audio.playedUrl, isNull);
    await cubit.close();
    await dir.delete(recursive: true);
  });

  test('streams when not downloaded but online', () async {
    final cubit = build(true);
    await cubit.toggle(2);

    expect(audio.playedUrl, 'https://server/002.mp3');
    expect(audio.playedFile, isNull);
    await cubit.close();
  });

  test('shows a notice when not downloaded and offline', () async {
    final cubit = build(false);
    await cubit.toggle(2);

    expect(audio.playedFile, isNull);
    expect(audio.playedUrl, isNull);
    expect(cubit.state.notice, isNotEmpty);
    expect(cubit.state.noticeSeq, 1);
    await cubit.close();
  });
}
