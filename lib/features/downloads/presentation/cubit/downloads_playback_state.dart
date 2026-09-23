part of 'downloads_playback_cubit.dart';

class DownloadsPlaybackState extends Equatable {
  /// The entry currently loaded in the player, or `null` when none is.
  final DownloadKey? currentKey;
  final bool isPlaying;

  /// One-shot user message (e.g. a missing file). [noticeSeq] changes on every
  /// new notice so the UI shows it exactly once.
  final String notice;
  final int noticeSeq;

  const DownloadsPlaybackState({
    this.currentKey,
    this.isPlaying = false,
    this.notice = '',
    this.noticeSeq = 0,
  });

  bool isCurrent(DownloadEntry entry) => currentKey == entry.key;

  /// [clearCurrentKey] is how a caller says "nothing is loaded now"; passing
  /// `currentKey: null` would just keep the current one.
  DownloadsPlaybackState copyWith({
    DownloadKey? currentKey,
    bool clearCurrentKey = false,
    bool? isPlaying,
    String? notice,
    int? noticeSeq,
  }) {
    return DownloadsPlaybackState(
      currentKey: clearCurrentKey ? null : (currentKey ?? this.currentKey),
      isPlaying: isPlaying ?? this.isPlaying,
      notice: notice ?? this.notice,
      noticeSeq: noticeSeq ?? this.noticeSeq,
    );
  }

  @override
  List<Object?> get props => [currentKey, isPlaying, notice, noticeSeq];
}
