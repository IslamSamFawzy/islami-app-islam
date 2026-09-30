part of 'mushaf_reader_bloc.dart';

class MushafReaderState extends Equatable {
  /// Status of opening the reader (finding the first page to show).
  final ViewStatus status;
  final String? errorMessage;

  /// The page on screen, 1-604.
  final int page;

  /// Bumped whenever the reader must move to [page] itself (opening, "Go
  /// to"), as opposed to the reader swiping there.
  final int jumpCount;

  /// Loaded pages near [page].
  final Map<int, MushafPage> pages;

  /// Pages that failed to load.
  final Set<int> failedPages;

  /// The ayah shown in gold: the one tapped, or the one resumed at.
  final AyahRef? selected;

  const MushafReaderState({
    this.status = ViewStatus.initial,
    this.errorMessage,
    this.page = 1,
    this.jumpCount = 0,
    this.pages = const {},
    this.failedPages = const {},
    this.selected,
  });

  MushafReaderState copyWith({
    ViewStatus? status,
    String? errorMessage,
    int? page,
    int? jumpCount,
    Map<int, MushafPage>? pages,
    Set<int>? failedPages,
    AyahRef? Function()? selected,
  }) {
    return MushafReaderState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      page: page ?? this.page,
      jumpCount: jumpCount ?? this.jumpCount,
      pages: pages ?? this.pages,
      failedPages: failedPages ?? this.failedPages,
      selected: selected != null ? selected() : this.selected,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    page,
    jumpCount,
    pages,
    failedPages,
    selected,
  ];
}
