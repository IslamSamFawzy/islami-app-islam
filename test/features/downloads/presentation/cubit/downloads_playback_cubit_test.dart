import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/services/audio_player_service.dart';
import 'package:islami/core/services/download_service.dart';
import 'package:islami/features/downloads/data/datasources/downloads_local_data_source.dart';
import 'package:islami/features/downloads/data/models/download_entry_model.dart';
import 'package:islami/features/downloads/domain/entities/download_entry.dart';
import 'package:islami/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:islami/features/downloads/presentation/cubit/downloads_playback_cubit.dart';

class _FakeAudio implements AudioPlayerService {
  final _controller = StreamController<PlayerState>.broadcast();
  String? playedFile;
  int stops = 0;
  int pauses = 0;
  int resumes = 0;

  @override
  Stream<PlayerState> get onStateChanged => _controller.stream;
  @override
  PlayerState get state => PlayerState.stopped;
  @override
  Future<void> playFile(String path) async => playedFile = path;
  @override
  Future<void> playUrl(String url) async {}
  @override
  Future<void> pause() async => pauses++;
  @override
  Future<void> resume() async => resumes++;
  @override
  Future<void> stop() async => stops++;
  @override
  Future<void> dispose() async => _controller.close();

  void emitState(PlayerState s) => _controller.add(s);
}

class _FakeDownloadService implements DownloadService {
  final List<String> deleted = [];
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
  Future<void> delete(String reciterId, String suraId) async =>
      deleted.add('$reciterId/$suraId');
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

class _FakeLocal implements DownloadsLocalDataSource {
  final Map<String, DownloadEntryModel> store = {};
  @override
  List<DownloadEntryModel> getAll() => store.values.toList();
  @override
  DownloadEntryModel? get(String reciterId, String suraId) =>
      store['$reciterId/$suraId'];
  @override
  Future<void> put(DownloadEntryModel entry) async => store[entry.key] = entry;
  @override
  Future<void> remove(String reciterId, String suraId) async =>
      store.remove('$reciterId/$suraId');
  @override
  Future<void> removeReciter(String reciterId) async =>
      store.removeWhere((k, _) => k.startsWith('$reciterId/'));
}

DownloadEntry _entry(String reciterId, String suraId, String path) =>
    DownloadEntry(
      reciterId: reciterId,
      reciterName: 'R',
      suraId: suraId,
      path: path,
      bytes: 1,
      downloadedAt: DateTime(2026),
    );

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late _FakeAudio audio;
  late _FakeDownloadService service;
  late _FakeLocal local;
  late DownloadsBloc bloc;

  DownloadsPlaybackCubit build() => DownloadsPlaybackCubit(
    audioPlayerService: audio,
    downloadService: service,
    downloadsBloc: bloc,
  );

  setUp(() {
    audio = _FakeAudio();
    service = _FakeDownloadService();
    local = _FakeLocal();
    bloc = DownloadsBloc(downloadService: service, localDataSource: local);
  });

  tearDown(() => bloc.close());

  test('plays a local file that exists and marks it current', () async {
    final dir = await Directory.systemTemp.createTemp('dl_play');
    final file = File('${dir.path}/2.mp3');
    await file.writeAsString('audio');
    final entry = _entry('1', '2', file.path);

    final cubit = build();
    await cubit.toggle(entry);

    expect(audio.playedFile, file.path);
    expect(cubit.state.currentKey, entry.key);

    await cubit.close();
    await dir.delete(recursive: true);
  });

  test('tapping the current entry pauses, then resumes', () async {
    final dir = await Directory.systemTemp.createTemp('dl_toggle');
    final file = File('${dir.path}/2.mp3');
    await file.writeAsString('audio');
    final entry = _entry('1', '2', file.path);

    final cubit = build();
    await cubit.toggle(entry); // start
    audio.emitState(PlayerState.playing);
    await _settle();

    await cubit.toggle(entry); // same → pause
    expect(audio.pauses, 1);

    audio.emitState(PlayerState.paused);
    await _settle();
    await cubit.toggle(entry); // same → resume
    expect(audio.resumes, 1);

    await cubit.close();
    await dir.delete(recursive: true);
  });

  test('a missing file shows a notice and reconciles the index', () async {
    // Seed the index with an entry whose file does not exist.
    local.store['1/2'] = DownloadEntryModel(
      reciterId: '1',
      reciterName: 'R',
      suraId: '2',
      path: '/no/such/file.mp3',
      bytes: 1,
      downloadedAt: DateTime(2026),
    );
    final cubit = build();

    await cubit.toggle(_entry('1', '2', '/no/such/file.mp3'));

    expect(audio.playedFile, isNull);
    expect(cubit.state.notice, isNotEmpty);
    expect(cubit.state.noticeSeq, 1);

    // The cubit asked DownloadsBloc to reconcile, which drops the stale entry.
    await _settle();
    expect(local.store, isEmpty);

    await cubit.close();
  });

  test('stopIfCurrent stops the playing entry, ignores others', () async {
    final dir = await Directory.systemTemp.createTemp('dl_stop');
    final file = File('${dir.path}/2.mp3');
    await file.writeAsString('audio');
    final entry = _entry('1', '2', file.path);

    final cubit = build();
    await cubit.toggle(entry);

    await cubit.stopIfCurrent(_entry('9', '9', 'x')); // not current
    expect(audio.stops, 0);

    await cubit.stopIfCurrent(entry); // current
    expect(audio.stops, 1);
    expect(cubit.state.currentKey, isEmpty);

    await cubit.close();
    await dir.delete(recursive: true);
  });

  test('close stops only when this screen owns the audio', () async {
    final fresh = build();
    await fresh.close();
    expect(audio.stops, 0); // never played here → do not touch the player

    final dir = await Directory.systemTemp.createTemp('dl_close');
    final file = File('${dir.path}/2.mp3');
    await file.writeAsString('audio');
    final cubit = build();
    await cubit.toggle(_entry('1', '2', file.path));
    await cubit.close();
    expect(audio.stops, 1);

    await dir.delete(recursive: true);
  });
}
