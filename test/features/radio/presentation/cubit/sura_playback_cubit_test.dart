import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/services/audio_player_service.dart';
import 'package:islami/core/services/connectivity_service.dart';
import 'package:islami/core/services/download_service.dart';
import 'package:islami/features/downloads/data/datasources/downloads_local_data_source.dart';
import 'package:islami/features/downloads/data/models/download_entry_model.dart';
import 'package:islami/features/downloads/data/repositories/downloads_repository_impl.dart';
import 'package:islami/features/downloads/domain/entities/download_key.dart';
import 'package:islami/features/downloads/domain/usecases/find_downloaded_file.dart';
import 'package:islami/features/radio/domain/entities/reciter.dart';
import 'package:islami/features/radio/presentation/cubit/sura_playback_cubit.dart';

class _FakeAudio implements AudioPlayerService {
  String? playedFile;
  String? playedUrl;
  int stops = 0;

  @override
  Stream<bool> get isPlayingStream => const Stream.empty();

  @override
  bool get isPlaying => false;

  @override
  Future<void> playFile(String path) async => playedFile = path;

  @override
  Future<void> playUrl(String url) async => playedUrl = url;

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> togglePause() async {}

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> dispose() async {}
}

class _FakeLocal implements DownloadsLocalDataSource {
  DownloadEntryModel? entry;

  @override
  DownloadEntryModel? get(DownloadKey key) => entry;

  @override
  List<DownloadEntryModel> getAll() => entry == null ? [] : [entry!];

  @override
  Future<void> put(DownloadEntryModel e) async {}

  @override
  Future<void> remove(DownloadKey key) async {}

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

class _FakeDownloadService implements DownloadService {
  @override
  Stream<double> get progress => const Stream.empty();
  @override
  Future<String> download({
    required String url,
    required String reciterId,
    required String suraId,
  }) async => '';
  @override
  void cancel() {}
  @override
  Future<void> delete(String reciterId, String suraId) async {}
  @override
  Future<void> deleteReciter(String reciterId) async {}
  @override
  Future<int> fileSize(String reciterId, String suraId) async => 0;
  @override
  Future<bool> fileExists(String reciterId, String suraId) async => false;
  @override
  Future<bool> pathExists(String path) async => File(path).exists();
  @override
  Future<String> filePath(String reciterId, String suraId) async => '';
  @override
  Future<void> dispose() async {}
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
  late _FakeDownloadService downloadService;

  SuraPlaybackCubit build(bool connected) => SuraPlaybackCubit(
    reciter: reciter,
    audioPlayerService: audio,
    findDownloadedFile: FindDownloadedFile(
      DownloadsRepositoryImpl(
        localDataSource: local,
        downloadService: downloadService,
      ),
    ),
    connectivityService: _FakeConnectivity(connected),
  );

  setUp(() {
    audio = _FakeAudio();
    local = _FakeLocal();
    downloadService = _FakeDownloadService();
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

  test('closing stops the audio only when this screen started it', () async {
    // The player is shared with Radio and Downloads, so leaving the sura list
    // without having played anything must not cut those off.
    final idle = build(true);
    await idle.close();
    expect(audio.stops, 0);

    final playing = build(true);
    await playing.toggle(2);
    await playing.close();
    expect(audio.stops, 1);
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
