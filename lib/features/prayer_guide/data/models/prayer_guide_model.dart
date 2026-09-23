import '../../domain/entities/prayer_guide.dart';
import '../../domain/entities/prayer_posture.dart';

class HadithEvidenceModel extends HadithEvidence {
  const HadithEvidenceModel({required super.text, required super.source});

  factory HadithEvidenceModel.fromJson(Map<String, dynamic> json) {
    return HadithEvidenceModel(
      text: json['text'] as String,
      source: json['source'] as String,
    );
  }
}

class PrayerStepModel extends PrayerStep {
  const PrayerStepModel({
    required super.title,
    required super.description,
    required super.recitation,
    required super.postures,
    required super.evidence,
  });

  factory PrayerStepModel.fromJson(Map<String, dynamic> json) {
    return PrayerStepModel(
      title: json['title'] as String,
      description: json['description'] as String,
      recitation: (json['recitation'] as String?) ?? '',
      postures: parsePostures(json['postures']),
      evidence: [
        for (final e in (json['evidence'] as List? ?? const []))
          HadithEvidenceModel.fromJson((e as Map).cast<String, dynamic>()),
      ],
    );
  }
}

class RakaatCountModel extends RakaatCount {
  const RakaatCountModel({required super.prayer, required super.count});

  factory RakaatCountModel.fromJson(Map<String, dynamic> json) {
    return RakaatCountModel(
      prayer: json['prayer'] as String,
      count: (json['count'] as num).toInt(),
    );
  }
}

class PrayerGuideModel extends PrayerGuide {
  const PrayerGuideModel({
    required super.title,
    required super.introHadith,
    required super.introText,
    required super.overviewPostures,
    required super.rakaat,
    required super.note,
    required super.steps,
  });

  factory PrayerGuideModel.fromJson(Map<String, dynamic> json) {
    return PrayerGuideModel(
      title: json['title'] as String,
      introHadith: HadithEvidenceModel.fromJson(
        (json['introHadith'] as Map).cast<String, dynamic>(),
      ),
      introText: json['introText'] as String,
      overviewPostures: parsePostures(json['overviewPostures']),
      rakaat: [
        for (final r in (json['rakaat'] as List? ?? const []))
          RakaatCountModel.fromJson((r as Map).cast<String, dynamic>()),
      ],
      note: (json['note'] as String?) ?? '',
      steps: [
        for (final s in (json['steps'] as List))
          PrayerStepModel.fromJson((s as Map).cast<String, dynamic>()),
      ],
    );
  }
}

/// Parses a JSON list of posture names. Throws [ArgumentError] on an unknown
/// name or an empty list, so a typo in the content file fails loudly instead
/// of rendering a frozen figure.
List<PrayerPosture> parsePostures(Object? raw) {
  final list = [
    for (final name in (raw as List? ?? const []))
      PrayerPosture.values.byName(name as String),
  ];
  if (list.isEmpty) {
    throw ArgumentError('A step needs at least one posture');
  }
  return list;
}
