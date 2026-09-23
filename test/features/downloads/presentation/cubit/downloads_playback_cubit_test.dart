import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/services/audio_player_service.dart';
import 'package:islami/core/services/download_service.dart';
import 'package:islami/features/downloads/data/datasources/downloads_local_data_source.dart';
import 'package:islami/features/downloads/data/models/download_entry_model.dart';
import 'package:islami/features/downloads/domain/entities/download_entry.dart';
import 'package:islami/features/downloads/data/repositories/downloads_repository_impl.dart';
import 'package:islami/features/downloads/domain/entities/download_key.dart';
import 'package:islami/features/downloads/domain/usecases/delete_download.dart';
import 'package:islami/features/downloads/domain/usecases/delete_reciter_downloads.dart';
import 'package:islami/features/downloads/domain/usecases/find_downloaded_file.dart';
import 'package:islami/features/downloads/domain/usecases/get_downloads.dart';
import 'package:islami/features/downloads/domain/usecases/reconcile_downloads.dart';
import 'package:islami/features/downloads/domain/usecases/save_download.dart';
import 'package:islami/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:islami/features/downloads/presentation/cubit/downloads_playback_cubit.dart';

class _FakeAudio implements AudioPlayerService {
  final _controller = StreamController<bool>.broadcast();
  String? playedFile;
  int stops = 0;
  int pauses = 0;
  int resumes = 0;
  bool _playing = false;

  @override
  Stream<bool> get isPlayingStream => _controller.stream;
  @override
  bool get isPlaying => _playing;
  @override
  Future<void> playFile(String path) async => playedFile = path;
  @override
  Future<void> playUrl(String url) async {}
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

  /// Mimics the player reporting that it started or stopped playing.
  void emitPlaying(bool playing) {
    _playing = playing;
    _controller.add(playing);
  }
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
  DownloadEntryModel? get(DownloadKey key) => store['$key'];
  @override
  Future<void> put(DownloadEntryModel entry) async =>
      store['${entry.key}'] = entry;
  @override
  Future<void> remove(DownloadKey key) async => store.remove('$key');
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

  /// An entry that is in the index, which is the only way the Downloads
  /// screen ever hands one to the cubit.
  DownloadEntry indexed(String reciterId, String suraId, String path) {
    final entry = _entry(reciterId, suraId, path);
    local.store['${entry.key}'] = DownloadEntryModel.fromEntry(entry);
    return entry;
  }

  DownloadsPlaybackCubit build() => DownloadsPlaybackCubit(
    audioPlayerService: audio,
    findDownloadedFile: FindDownloadedFile(
      DownloadsRepositoryImpl(localDataSource: local, downloadService: service),
    ),
    downloadsBloc: bloc,
  );

  setUp(() {
    audio = _FakeAudio();
    service = _FakeDownloadService();
    local = _FakeLocal();
    final repository = DownloadsRepositoryImpl(
      localDataSource: local,
      downloadService: service,
    );
    bloc = DownloadsBloc(
      downloadService: service,
      getDownloads: GetDownloads(repository),
      reconcileDownloads: ReconcileDownloads(repository),
      saveDownload: SaveDownload(repository),
      deleteDownload: DeleteDownload(repository),
      deleteReciterDownloads: DeleteReciterDownloads(repository),
    );
  });

  tearDown(() => bloc.close());

  test('plays a local file that exists and marks it current', () async {
    final dir = await Directory.systemTemp.createTemp('dl_play');
    final file = File('${dir.path}/2.mp3');
    await file.writeAsString('audio');
    final entry = indexed('1', '2', file.path);

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
    final entry = indexed('1', '2', file.path);

    final cubit = build();
    await cubit.toggle(entry); // start
    audio.emitPlaying(true);
    await _settle();

    await cubit.toggle(entry); // same → pause
    expect(audio.pauses, 1);

    audio.emitPlaying(false);
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
    expect(cubit.state.notice.message, isNotEmpty);
    expect(cubit.state.notice.id, 1);

    // The cubit asked DownloadsBloc to reconcile, which drops the stale entry.
    await _settle();
    expect(local.store, isEmpty);

    await cubit.close();
  });

  test('stopIfCurrent stops the playing entry, ignores others', () async {
    final dir = await Directory.systemTemp.createTemp('dl_stop');
    final file = File('${dir.path}/2.mp3');
    await file.writeAsString('audio');
    final entry = indexed('1', '2', file.path);

    final cubit = build();
    await cubit.toggle(entry);

    await cubit.stopIfCurrent(_entry('9', '9', 'x')); // not current
    expect(audio.stops, 0);

    await cubit.stopIfCurrent(entry); // current
    expect(audio.stops, 1);
    expect(cubit.state.currentKey, isNull);

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
    await cubit.toggle(indexed('1', '2', file.path));
    await cubit.close();
    expect(audio.stops, 1);

    await dir.delete(recursive: true);
  });
}
