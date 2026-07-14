part of 'downloads_bloc.dart';

abstract class DownloadsEvent extends Equatable {
  const DownloadsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the index and reconciles it against the filesystem on startup,
/// dropping entries whose file is gone.
class LoadDownloadsEvent extends DownloadsEvent {
  const LoadDownloadsEvent();
}

/// Queues a sura download (starts immediately if nothing is downloading).
class EnqueueDownloadEvent extends DownloadsEvent {
  final String reciterId;
  final String reciterName;
  final String suraId;
  final String url;

  const EnqueueDownloadEvent({
    required this.reciterId,
    required this.reciterName,
    required this.suraId,
    required this.url,
  });

  @override
  List<Object?> get props => [reciterId, reciterName, suraId, url];
}

/// Cancels a download, whether it is active or still queued.
class CancelDownloadEvent extends DownloadsEvent {
  final String reciterId;
  final String suraId;

  const CancelDownloadEvent({required this.reciterId, required this.suraId});

  @override
  List<Object?> get props => [reciterId, suraId];
}

/// Deletes a downloaded sura (file + index entry).
class DeleteDownloadEvent extends DownloadsEvent {
  final String reciterId;
  final String suraId;

  const DeleteDownloadEvent({required this.reciterId, required this.suraId});

  @override
  List<Object?> get props => [reciterId, suraId];
}

/// Deletes all downloads for a reciter.
class DeleteReciterDownloadsEvent extends DownloadsEvent {
  final String reciterId;

  const DeleteReciterDownloadsEvent(this.reciterId);

  @override
  List<Object?> get props => [reciterId];
}

/// Internal: latest progress for the active download.
class _DownloadProgressEvent extends DownloadsEvent {
  final double progress;

  const _DownloadProgressEvent(this.progress);

  @override
  List<Object?> get props => [progress];
}

/// Internal: the active download finished successfully.
class _DownloadCompletedEvent extends DownloadsEvent {
  final DownloadEntry entry;

  const _DownloadCompletedEvent(this.entry);

  @override
  List<Object?> get props => [entry];
}

/// Internal: the active download failed or was cancelled.
class _DownloadFailedEvent extends DownloadsEvent {
  final String key;

  const _DownloadFailedEvent(this.key);

  @override
  List<Object?> get props => [key];
}
