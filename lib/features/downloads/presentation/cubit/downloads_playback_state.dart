part of 'downloads_playback_cubit.dart';

class DownloadsPlaybackState extends Equatable {
  /// The entry currently loaded in the player, or `null` when none is.
  final DownloadKey? currentKey;
  final bool isPlaying;

  /// One-shot user message (e.g. a missing file).
  final UiNotice notice;

  const DownloadsPlaybackState({
    this.currentKey,
    this.isPlaying = false,
    this.notice = const UiNotice.none(),
  });

  bool isCurrent(DownloadEntry entry) => currentKey == entry.key;

  /// [clearCurrentKey] is how a caller says "nothing is loaded now"; passing
  /// `currentKey: null` would just keep the current one.
  DownloadsPlaybackState copyWith({
    DownloadKey? currentKey,
    bool clearCurrentKey = false,
    bool? isPlaying,
    UiNotice? notice,
  }) {
    return DownloadsPlaybackState(
      currentKey: clearCurrentKey ? null : (currentKey ?? this.currentKey),
      isPlaying: isPlaying ?? this.isPlaying,
      notice: notice ?? this.notice,
    );
  }

  @override
  List<Object?> get props => [currentKey, isPlaying, notice];
}
