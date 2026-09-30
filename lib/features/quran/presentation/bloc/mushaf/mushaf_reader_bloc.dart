import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/presentation/view_status.dart';
import '../../../domain/entities/ayah_ref.dart';
import '../../../domain/entities/mushaf_page.dart';
import '../../../domain/entities/reading_progress.dart';
import '../../../domain/usecases/add_recent_sura.dart';
import '../../../domain/usecases/get_juz_start.dart';
import '../../../domain/usecases/get_mushaf_page.dart';
import '../../../domain/usecases/get_page_for_ayah.dart';
import '../../../domain/usecases/get_reading_progress.dart';
import '../../../domain/usecases/get_sura_info.dart';
import '../../../domain/usecases/save_reading_progress.dart';

part 'mushaf_reader_event.dart';
part 'mushaf_reader_state.dart';

/// The Mushaf reader: which page is on screen, the pages around it, the
/// selected ayah, and where the reader is (saved as reading progress).
class MushafReaderBloc extends Bloc<MushafReaderEvent, MushafReaderState> {
  final GetPage getPage;
  final GetPageForAyah getPageForAyah;
  final GetSuraInfo getSuraInfo;
  final GetJuzStart getJuzStart;
  final GetReadingProgress getReadingProgress;
  final SaveReadingProgress saveReadingProgress;
  final AddRecentSura addRecentSura;

  static const int pageCount = 604;

  /// How long a page must stay on screen before it counts as read to.
  static const Duration saveDebounce = Duration(milliseconds: 800);

  /// How long the resumed ayah stays highlighted.
  static const Duration highlightDuration = Duration(seconds: 2);

  /// Pages kept loaded either side of the one on screen.
  static const int keepAround = 2;

  /// Where the reader is, not yet written.
  AyahRef? _unsaved;

  /// A page swiped to before it had loaded: its first ayah is where the
  /// reader is, once it arrives.
  int? _markOnArrival;
  Timer? _saveTimer;
  Timer? _highlightTimer;

  MushafReaderBloc({
    required this.getPage,
    required this.getPageForAyah,
    required this.getSuraInfo,
    required this.getJuzStart,
    required this.getReadingProgress,
    required this.saveReadingProgress,
    required this.addRecentSura,
  }) : super(const MushafReaderState()) {
    on<MushafOpenedEvent>(_onOpened);
    on<MushafPageChangedEvent>(_onPageChanged);
    on<MushafPageNeededEvent>(_onPageNeeded);
    on<MushafAyahTappedEvent>(_onAyahTapped);
    on<MushafGoToEvent>(_onGoTo);
    on<MushafSaveNowEvent>((_, _) => _saveNow());
    on<_ClearHighlightEvent>(
      (_, emit) => emit(state.copyWith(selected: () => null)),
    );
  }

  Future<void> _onOpened(
    MushafOpenedEvent event,
    Emitter<MushafReaderState> emit,
  ) async {
    emit(state.copyWith(status: ViewStatus.loading));

    // Resuming: the page of the saved ayah, with that ayah briefly in gold.
    if (event.resume) {
      final saved = (await getReadingProgress(event.sura)).fold(
        (_) => null,
        (ReadingProgress? p) => p,
      );
      if (saved != null) {
        final ayah = AyahRef(event.sura, saved.ayah);
        final page = (await getPageForAyah(ayah)).fold((_) => null, (p) => p);
        if (page != null) {
          emit(
            state.copyWith(
              status: ViewStatus.success,
              page: page,
              jumpCount: state.jumpCount + 1,
              selected: () => ayah,
            ),
          );
          _clearHighlightLater();
          return;
        }
        // A saved ayah the Mushaf doesn't have: open the sura at the top.
      }
    }

    final result = await getSuraInfo(event.sura);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ViewStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (info) => emit(
        state.copyWith(
          status: ViewStatus.success,
          page: info.firstPage,
          jumpCount: state.jumpCount + 1,
        ),
      ),
    );
  }

  void _onPageChanged(
    MushafPageChangedEvent event,
    Emitter<MushafReaderState> emit,
  ) {
    if (event.page == state.page) return;
    emit(state.copyWith(page: event.page, pages: _near(event.page)));
    // Have the neighbours ready before they are swiped to.
    for (final p in [event.page, event.page + 1, event.page - 1]) {
      add(MushafPageNeededEvent(p));
    }

    // Swiping counts as reading on to this page: its first ayah.
    final loaded = state.pages[event.page];
    if (loaded == null) {
      _markOnArrival = event.page;
    } else {
      _markFirstAyah(loaded);
    }
  }

  Future<void> _onPageNeeded(
    MushafPageNeededEvent event,
    Emitter<MushafReaderState> emit,
  ) async {
    final n = event.page;
    if (n < 1 || n > pageCount || state.pages.containsKey(n)) return;
    // A page far from the reader by the time it loads is not kept.
    final result = await getPage(n);
    if ((n - state.page).abs() > keepAround) return;
    result.fold(
      (_) => emit(state.copyWith(failedPages: {...state.failedPages, n})),
      (page) {
        emit(
          state.copyWith(
            pages: {..._near(state.page), n: page},
            failedPages: {...state.failedPages}..remove(n),
          ),
        );
        if (n == _markOnArrival) _markFirstAyah(page);
      },
    );
  }

  void _markFirstAyah(MushafPage page) {
    _markOnArrival = null;
    final first = page.words.firstOrNull;
    if (first != null) _markRead(AyahRef(first.sura, first.ayah));
  }

  void _onAyahTapped(
    MushafAyahTappedEvent event,
    Emitter<MushafReaderState> emit,
  ) {
    _highlightTimer?.cancel();
    // Tapping the selected ayah again clears the highlight.
    final next = state.selected == event.ayah ? null : event.ayah;
    emit(state.copyWith(selected: () => next));
    _markRead(event.ayah);
  }

  Future<void> _onGoTo(
    MushafGoToEvent event,
    Emitter<MushafReaderState> emit,
  ) async {
    final target = event.target;
    AyahRef? highlight;
    int? page;
    switch (target) {
      case PageTarget(page: final n):
        page = n >= 1 && n <= pageCount ? n : null;
      case SuraTarget(:final sura):
        page = (await getSuraInfo(sura)).fold((_) => null, (i) => i.firstPage);
      case JuzTarget(:final juz):
        page = (await getJuzStart(juz)).fold((_) => null, (a) => a.page);
      case AyahTarget(:final ayah):
        page = (await getPageForAyah(ayah)).fold((_) => null, (p) => p);
        highlight = ayah;
    }
    if (page == null) return;
    _jump(emit, page, highlight: highlight);
  }

  void _jump(Emitter<MushafReaderState> emit, int page, {AyahRef? highlight}) {
    emit(
      state.copyWith(
        page: page,
        jumpCount: state.jumpCount + 1,
        pages: _near(page),
        selected: () => highlight,
      ),
    );
    if (highlight != null) {
      _clearHighlightLater();
      _markRead(highlight);
    }
    for (final p in [page, page + 1, page - 1]) {
      add(MushafPageNeededEvent(p));
    }
  }

  /// The loaded pages worth keeping around [page].
  Map<int, MushafPage> _near(int page) => {
    for (final e in state.pages.entries)
      if ((e.key - page).abs() <= keepAround) e.key: e.value,
  };

  void _clearHighlightLater() {
    _highlightTimer?.cancel();
    _highlightTimer = Timer(highlightDuration, () {
      if (!isClosed) add(const _ClearHighlightEvent());
    });
  }

  /// Remembers [ayah] as where the reader is, and writes it once they stop.
  void _markRead(AyahRef ayah) {
    if (ayah == _unsaved) return;
    _unsaved = ayah;
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDebounce, () {
      if (!isClosed) add(const MushafSaveNowEvent());
    });
  }

  Future<void> _saveNow() async {
    _saveTimer?.cancel();
    final ayah = _unsaved;
    if (ayah == null) return;
    _unsaved = null;
    await saveReadingProgress(
      ReadingProgress(
        suraId: ayah.sura,
        ayah: ayah.ayah,
        updatedAt: DateTime.now(),
      ),
    );
    await addRecentSura(AddRecentSuraParams(ayah.sura));
  }

  @override
  Future<void> close() async {
    _highlightTimer?.cancel();
    // Leaving the reader counts as stopping there, debounce or not.
    await _saveNow();
    return super.close();
  }
}
