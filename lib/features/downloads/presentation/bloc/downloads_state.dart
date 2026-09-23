part of 'downloads_bloc.dart';

class DownloadsState extends Equatable {
  /// Completed downloads, by key.
  final Map<DownloadKey, DownloadEntry> entries;

  /// The sura currently downloading, or `null` when nothing is.
  final DownloadKey? activeKey;

  /// Progress of the active download, 0.0–1.0.
  final double activeProgress;

  /// Downloads queued behind the active one, in order.
  final List<DownloadKey> queue;

  const DownloadsState({
    this.entries = const {},
    this.activeKey,
    this.activeProgress = 0,
    this.queue = const [],
  });

  bool isDownloaded(String reciterId, String suraId) =>
      entries.containsKey(DownloadKey(reciterId: reciterId, suraId: suraId));

  bool isDownloading(String reciterId, String suraId) =>
      activeKey == DownloadKey(reciterId: reciterId, suraId: suraId);

  bool isQueued(String reciterId, String suraId) =>
      queue.contains(DownloadKey(reciterId: reciterId, suraId: suraId));

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

  /// [clearActiveKey] is how a caller says "nothing is downloading now";
  /// passing `activeKey: null` would just keep the current one.
  DownloadsState copyWith({
    Map<DownloadKey, DownloadEntry>? entries,
    DownloadKey? activeKey,
    bool clearActiveKey = false,
    double? activeProgress,
    List<DownloadKey>? queue,
  }) {
    return DownloadsState(
      entries: entries ?? this.entries,
      activeKey: clearActiveKey ? null : (activeKey ?? this.activeKey),
      activeProgress: activeProgress ?? this.activeProgress,
      queue: queue ?? this.queue,
    );
  }

  @override
  List<Object?> get props => [entries, activeKey, activeProgress, queue];
}
