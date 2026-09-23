part of 'sura_playback_cubit.dart';

class SuraPlaybackState extends Equatable {
  /// Sura number (as a string) currently loaded, or `''` when nothing plays.
  final String currentSuraId;
  final bool isPlaying;

  /// A one-shot user message (e.g. "download to play offline").
  final UiNotice notice;

  const SuraPlaybackState({
    this.currentSuraId = '',
    this.isPlaying = false,
    this.notice = const UiNotice.none(),
  });

  bool isCurrent(int sura) => currentSuraId == sura.toString();

  SuraPlaybackState copyWith({
    String? currentSuraId,
    bool? isPlaying,
    UiNotice? notice,
  }) {
    return SuraPlaybackState(
      currentSuraId: currentSuraId ?? this.currentSuraId,
      isPlaying: isPlaying ?? this.isPlaying,
      notice: notice ?? this.notice,
    );
  }

  @override
  List<Object?> get props => [currentSuraId, isPlaying, notice];
}
