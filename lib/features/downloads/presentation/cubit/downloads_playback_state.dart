part of 'downloads_playback_cubit.dart';

class DownloadsPlaybackState extends Equatable {
  /// Key (`<reciterId>/<suraId>`) of the entry currently loaded, or `''`.
  final String currentKey;
  final bool isPlaying;

  /// One-shot user message (e.g. a missing file). [noticeSeq] changes on every
  /// new notice so the UI shows it exactly once.
  final String notice;
  final int noticeSeq;

  const DownloadsPlaybackState({
    this.currentKey = '',
    this.isPlaying = false,
    this.notice = '',
    this.noticeSeq = 0,
  });

  bool isCurrent(DownloadEntry entry) => currentKey == entry.key;

  DownloadsPlaybackState copyWith({
    String? currentKey,
    bool? isPlaying,
    String? notice,
    int? noticeSeq,
  }) {
    return DownloadsPlaybackState(
      currentKey: currentKey ?? this.currentKey,
      isPlaying: isPlaying ?? this.isPlaying,
      notice: notice ?? this.notice,
      noticeSeq: noticeSeq ?? this.noticeSeq,
    );
  }

  @override
  List<Object?> get props => [currentKey, isPlaying, notice, noticeSeq];
}
