part of 'downloads_bloc.dart';

class DownloadsState extends Equatable {
  /// Completed downloads keyed by `<reciterId>/<suraId>`.
  final Map<String, DownloadEntry> entries;

  /// Key of the sura currently downloading, or `''` when idle.
  final String activeKey;

  /// Progress of the active download, 0.0–1.0.
  final double activeProgress;

  /// Keys queued behind the active download, in order.
  final List<String> queue;

  const DownloadsState({
    this.entries = const {},
    this.activeKey = '',
    this.activeProgress = 0,
    this.queue = const [],
  });

  static String keyOf(String reciterId, String suraId) => '$reciterId/$suraId';

  bool isDownloaded(String reciterId, String suraId) =>
      entries.containsKey(keyOf(reciterId, suraId));

  bool isDownloading(String reciterId, String suraId) =>
      activeKey == keyOf(reciterId, suraId);

  bool isQueued(String reciterId, String suraId) =>
      queue.contains(keyOf(reciterId, suraId));

  /// Progress for a specific sura (0 unless it is the active download).
  double progressFor(String reciterId, String suraId) =>
      isDownloading(reciterId, suraId) ? activeProgress : 0;

  List<DownloadEntry> entriesForReciter(String reciterId) =>
      entries.values.where((e) => e.reciterId == reciterId).toList();

  int bytesForReciter(String reciterId) =>
      entriesForReciter(reciterId).fold(0, (sum, e) => sum + e.bytes);

  int get totalBytes => entries.values.fold(0, (sum, e) => sum + e.bytes);

  /// Distinct reciter ids that have at least one download.
  List<String> get reciterIds =>
      entries.values.map((e) => e.reciterId).toSet().toList();

  DownloadsState copyWith({
    Map<String, DownloadEntry>? entries,
    String? activeKey,
    double? activeProgress,
    List<String>? queue,
  }) {
    return DownloadsState(
      entries: entries ?? this.entries,
      activeKey: activeKey ?? this.activeKey,
      activeProgress: activeProgress ?? this.activeProgress,
      queue: queue ?? this.queue,
    );
  }

  @override
  List<Object?> get props => [entries, activeKey, activeProgress, queue];
}
