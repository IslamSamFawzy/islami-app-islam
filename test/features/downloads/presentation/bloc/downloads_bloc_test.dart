import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/services/download_service.dart';
import 'package:islami/features/downloads/data/datasources/downloads_local_data_source.dart';
import 'package:islami/features/downloads/data/models/download_entry_model.dart';
import 'package:islami/features/downloads/data/repositories/downloads_repository_impl.dart';
import 'package:islami/features/downloads/domain/entities/download_key.dart';
import 'package:islami/features/downloads/domain/usecases/delete_download.dart';
import 'package:islami/features/downloads/domain/usecases/delete_reciter_downloads.dart';
import 'package:islami/features/downloads/domain/usecases/get_downloads.dart';
import 'package:islami/features/downloads/domain/usecases/reconcile_downloads.dart';
import 'package:islami/features/downloads/domain/usecases/save_download.dart';
import 'package:islami/features/downloads/presentation/bloc/downloads_bloc.dart';

class _FakeDownloadService implements DownloadService {
  final _controller = StreamController<double>.broadcast();
  final List<String> downloaded = [];
  final Set<String> _existingPaths = {};

  @override
  Stream<double> get progress => _controller.stream;

  @override
  Future<String> download({
    required String url,
    required String reciterId,
    required String suraId,
  }) async {
    _controller.add(0.5);
    _controller.add(1.0);
    downloaded.add('$reciterId/$suraId');
    final path = '/fake/$reciterId/$suraId.mp3';
    _existingPaths.add(path);
    return path;
  }

  @override
  void cancel() {}

  @override
  Future<void> delete(String reciterId, String suraId) async {
    _existingPaths.remove('/fake/$reciterId/$suraId.mp3');
  }

  @override
  Future<void> deleteReciter(String reciterId) async {
    _existingPaths.removeWhere((p) => p.contains('/$reciterId/'));
  }

  @override
  Future<int> fileSize(String reciterId, String suraId) async => 2048;

  @override
  Future<bool> fileExists(String reciterId, String suraId) async =>
      _existingPaths.contains('/fake/$reciterId/$suraId.mp3');

  @override
  Future<bool> pathExists(String path) async => _existingPaths.contains(path);

  @override
  Future<String> filePath(String reciterId, String suraId) async =>
      '/fake/$reciterId/$suraId.mp3';

  @override
  Future<void> dispose() async => _controller.close();
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

void main() {
  late _FakeDownloadService service;
  late _FakeLocal local;
  late DownloadsBloc bloc;

  setUp(() {
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

  test('enqueue downloads a sura and records it in the index', () async {
    bloc.add(
      const EnqueueDownloadEvent(
        reciterId: '1',
        reciterName: 'R1',
        suraId: '2',
        url: 'u',
      ),
    );

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<DownloadsState>(
          (s) =>
              s.isDownloaded('1', '2') &&
              s.activeKey == null &&
              s.queue.isEmpty,
        ),
      ),
    );
    expect(local.get(const DownloadKey(reciterId: '1', suraId: '2')), isNotNull);
  });

  test('a queued second download runs after the first drains', () async {
    bloc.add(
      const EnqueueDownloadEvent(
        reciterId: '1',
        reciterName: 'R1',
        suraId: '2',
        url: 'u1',
      ),
    );
    bloc.add(
      const EnqueueDownloadEvent(
        reciterId: '1',
        reciterName: 'R1',
        suraId: '3',
        url: 'u2',
      ),
    );

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<DownloadsState>(
          (s) =>
              s.isDownloaded('1', '2') &&
              s.isDownloaded('1', '3') &&
              s.activeKey == null &&
              s.queue.isEmpty,
        ),
      ),
    );
    expect(service.downloaded, ['1/2', '1/3']);
  });

  test('delete removes a sura from the index', () async {
    bloc.add(
      const EnqueueDownloadEvent(
        reciterId: '1',
        reciterName: 'R1',
        suraId: '2',
        url: 'u',
      ),
    );
    await expectLater(
      bloc.stream,
      emitsThrough(predicate<DownloadsState>((s) => s.isDownloaded('1', '2'))),
    );

    bloc.add(const DeleteDownloadEvent(reciterId: '1', suraId: '2'));
    await expectLater(
      bloc.stream,
      emitsThrough(predicate<DownloadsState>((s) => !s.isDownloaded('1', '2'))),
    );
    expect(local.get(const DownloadKey(reciterId: '1', suraId: '2')), isNull);
  });
}
