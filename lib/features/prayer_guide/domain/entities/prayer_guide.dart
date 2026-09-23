import 'package:equatable/equatable.dart';

import 'prayer_posture.dart';

/// A hadith quoted as the evidence for a step, with its reference.
class HadithEvidence extends Equatable {
  final String text;
  final String source;

  const HadithEvidence({required this.text, required this.source});

  @override
  List<Object?> get props => [text, source];
}

/// One step of the prayer: what to do, what to say, and why.
class PrayerStep extends Equatable {
  final String title;
  final String description;

  /// What the worshipper says during this step (empty when nothing).
  final String recitation;

  /// Postures the animation cycles through for this step (at least one).
  final List<PrayerPosture> postures;

  final List<HadithEvidence> evidence;

  const PrayerStep({
    required this.title,
    required this.description,
    required this.recitation,
    required this.postures,
    required this.evidence,
  });

  @override
  List<Object?> get props => [title, description, recitation, postures, evidence];
}

/// Number of rak'at for one of the five daily prayers.
class RakaatCount extends Equatable {
  final String prayer;
  final int count;

  const RakaatCount({required this.prayer, required this.count});

  @override
  List<Object?> get props => [prayer, count];
}

/// The whole guide: an overview (full rak'ah animation + the hadith that
/// explains why we pray this way) followed by the individual steps.
class PrayerGuide extends Equatable {
  final String title;
  final HadithEvidence introHadith;
  final String introText;
  final List<PrayerPosture> overviewPostures;
  final List<RakaatCount> rakaat;
  final String note;
  final List<PrayerStep> steps;

  const PrayerGuide({
    required this.title,
    required this.introHadith,
    required this.introText,
    required this.overviewPostures,
    required this.rakaat,
    required this.note,
    required this.steps,
  });

  @override
  List<Object?> get props =>
      [title, introHadith, introText, overviewPostures, rakaat, note, steps];
}
