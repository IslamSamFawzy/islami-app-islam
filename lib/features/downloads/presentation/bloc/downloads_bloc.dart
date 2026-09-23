import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/download_service.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/download_entry.dart';
import '../../domain/entities/download_key.dart';
import '../../domain/usecases/delete_download.dart';
import '../../domain/usecases/delete_reciter_downloads.dart';
import '../../domain/usecases/get_downloads.dart';
import '../../domain/usecases/reconcile_downloads.dart';
import '../../domain/usecases/save_download.dart';

part 'downloads_event.dart';
part 'downloads_state.dart';

/// Owns the download queue (one download at a time), per-item progress, and the
/// on-disk index. Registered app-wide so downloads survive screen changes.
class DownloadsBloc extends Bloc<DownloadsEvent, DownloadsState> {
  /// The transfer itself: the queue and its progress live here, the saved
  /// library behind the use cases.
  final DownloadService downloadService;

  final GetDownloads getDownloads;
  final ReconcileDownloads reconcileDownloads;
  final SaveDownload saveDownload;
  final DeleteDownload deleteDownload;
  final DeleteReciterDownloads deleteReciterDownloads;

  StreamSubscription<double>? _progressSub;

  /// URLs for queued/active keys, needed to (re)start a download.
  final Map<DownloadKey, String> _urls = {};

  /// Display names by reciter id, so completed entries can be labelled.
  final Map<String, String> _reciterNames = {};

  DownloadsBloc({
    required this.downloadService,
    required this.getDownloads,
    required this.reconcileDownloads,
    required this.saveDownload,
    required this.deleteDownload,
    required this.deleteReciterDownloads,
  }) : super(const DownloadsState()) {
    on<LoadDownloadsEvent>(_onLoad);
    on<EnqueueDownloadEvent>(_onEnqueue);
    on<CancelDownloadEvent>(_onCancel);
    on<DeleteDownloadEvent>(_onDelete);
    on<DeleteReciterDownloadsEvent>(_onDeleteReciter);
    on<_DownloadProgressEvent>(_onProgress);
    on<_DownloadCompletedEvent>(_onCompleted);
    on<_DownloadFailedEvent>(_onFailed);

    _progressSub = downloadService.progress.listen((p) {
      if (!isClosed) add(_DownloadProgressEvent(p));
    });
  }

  Future<void> _onLoad(
    LoadDownloadsEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    final result = await reconcileDownloads(const NoParams());
    // On a storage failure the library on screen stays as it is — there is
    // nothing useful to tell the user about the index.
    result.fold(
      (_) {},
      (entries) => emit(state.copyWith(entries: _byKey(entries))),
    );
  }

  Future<void> _onEnqueue(
    EnqueueDownloadEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    final key = DownloadKey(
      reciterId: event.reciterId,
      suraId: event.suraId,
    );
    if (state.entries.containsKey(key) ||
        state.activeKey == key ||
        state.queue.contains(key)) {
      return; // already downloaded, active, or queued
    }
    _urls[key] = event.url;
    _reciterNames[event.reciterId] = event.reciterName;
    emit(state.copyWith(queue: [...state.queue, key]));
    _maybeStartNext(emit);
  }

  void _maybeStartNext(Emitter<DownloadsState> emit) {
    if (state.activeKey != null || state.queue.isEmpty) return;
    final key = state.queue.first;
    final url = _urls[key];
    final rest = state.queue.sublist(1);
    if (url == null) {
      emit(state.copyWith(queue: rest));
      return;
    }
    emit(state.copyWith(queue: rest, activeKey: key, activeProgress: 0));
    _beginDownload(key, url);
  }

  void _beginDownload(DownloadKey key, String url) {
    final reciterId = key.reciterId;
    final suraId = key.suraId;
    downloadService
        .download(url: url, reciterId: reciterId, suraId: suraId)
        .then((path) async {
          final bytes = await downloadService.fileSize(reciterId, suraId);
          if (!isClosed) {
            add(
              _DownloadCompletedEvent(
                DownloadEntry(
                  reciterId: reciterId,
                  reciterName: _reciterNames[reciterId] ?? '',
                  suraId: suraId,
                  path: path,
                  bytes: bytes,
                  downloadedAt: DateTime.now(),
                ),
              ),
            );
          }
        })
        .catchError((_) {
          if (!isClosed) add(_DownloadFailedEvent(key));
        });
  }

  void _onProgress(_DownloadProgressEvent event, Emitter<DownloadsState> emit) {
    if (state.activeKey == null) return;
    emit(state.copyWith(activeProgress: event.progress));
  }

  Future<void> _onCompleted(
    _DownloadCompletedEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    await saveDownload(event.entry);
    _urls.remove(event.entry.key);
    emit(
      state.copyWith(
        entries: await _savedEntries(),
        clearActiveKey: true,
        activeProgress: 0,
      ),
    );
    _maybeStartNext(emit);
  }

  void _onFailed(_DownloadFailedEvent event, Emitter<DownloadsState> emit) {
    _urls.remove(event.key);
    // A late failure for a no-longer-active key (e.g. cancelled) just advances.
    if (state.activeKey == event.key) {
      emit(state.copyWith(clearActiveKey: true, activeProgress: 0));
    }
    _maybeStartNext(emit);
  }

  Future<void> _onCancel(
    CancelDownloadEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    final key = DownloadKey(
      reciterId: event.reciterId,
      suraId: event.suraId,
    );
    _urls.remove(key);
    if (state.activeKey == key) {
      // Clear active first so the resulting failure is a no-op, then cancel.
      emit(state.copyWith(clearActiveKey: true, activeProgress: 0));
      downloadService.cancel();
      _maybeStartNext(emit);
    } else if (state.queue.contains(key)) {
      emit(state.copyWith(queue: state.queue.where((k) => k != key).toList()));
    }
  }

  Future<void> _onDelete(
    DeleteDownloadEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    await deleteDownload(
      DownloadKey(reciterId: event.reciterId, suraId: event.suraId),
    );
    emit(state.copyWith(entries: await _savedEntries()));
  }

  Future<void> _onDeleteReciter(
    DeleteReciterDownloadsEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    await deleteReciterDownloads(event.reciterId);
    emit(state.copyWith(entries: await _savedEntries()));
  }

  /// Re-reads the index after a change, so the screen shows what is actually
  /// saved rather than a copy patched by hand. Falls back to what is already
  /// on screen if the read fails.
  Future<Map<DownloadKey, DownloadEntry>> _savedEntries() async {
    final result = await getDownloads(const NoParams());
    return result.fold((_) => state.entries, _byKey);
  }

  Map<DownloadKey, DownloadEntry> _byKey(List<DownloadEntry> entries) => {
    for (final entry in entries) entry.key: entry,
  };

  @override
  Future<void> close() {
    _progressSub?.cancel();
    return super.close();
  }
}
