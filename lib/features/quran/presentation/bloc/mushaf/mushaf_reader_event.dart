part of 'mushaf_reader_bloc.dart';

abstract class MushafReaderEvent extends Equatable {
  const MushafReaderEvent();

  @override
  List<Object?> get props => [];
}

/// Opens the reader on [sura]: at its first page, or with [resume] where the
/// reader left off in it.
class MushafOpenedEvent extends MushafReaderEvent {
  final int sura;
  final bool resume;

  const MushafOpenedEvent(this.sura, {this.resume = false});

  @override
  List<Object?> get props => [sura, resume];
}

/// The page view settled on [page].
class MushafPageChangedEvent extends MushafReaderEvent {
  final int page;

  const MushafPageChangedEvent(this.page);

  @override
  List<Object?> get props => [page];
}

/// Page [page] is about to be shown and needs its content.
class MushafPageNeededEvent extends MushafReaderEvent {
  final int page;

  const MushafPageNeededEvent(this.page);

  @override
  List<Object?> get props => [page];
}

/// The reader tapped an ayah.
class MushafAyahTappedEvent extends MushafReaderEvent {
  final AyahRef ayah;

  const MushafAyahTappedEvent(this.ayah);

  @override
  List<Object?> get props => [ayah];
}

/// Where "Go to" can take the reader.
sealed class MushafTarget extends Equatable {
  const MushafTarget();
}

class SuraTarget extends MushafTarget {
  final int sura;

  const SuraTarget(this.sura);

  @override
  List<Object?> get props => [sura];
}

class JuzTarget extends MushafTarget {
  final int juz;

  const JuzTarget(this.juz);

  @override
  List<Object?> get props => [juz];
}

class PageTarget extends MushafTarget {
  final int page;

  const PageTarget(this.page);

  @override
  List<Object?> get props => [page];
}

class AyahTarget extends MushafTarget {
  final AyahRef ayah;

  const AyahTarget(this.ayah);

  @override
  List<Object?> get props => [ayah];
}

/// Go to a sura, a juz, a page or an ayah.
class MushafGoToEvent extends MushafReaderEvent {
  final MushafTarget target;

  const MushafGoToEvent(this.target);

  @override
  List<Object?> get props => [target];
}

/// Write the reading position now (leaving, or going to the background).
class MushafSaveNowEvent extends MushafReaderEvent {
  const MushafSaveNowEvent();
}

class _ClearHighlightEvent extends MushafReaderEvent {
  const _ClearHighlightEvent();
}
