import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/prayer_guide/data/models/prayer_guide_model.dart';
import 'package:islami/features/prayer_guide/domain/entities/prayer_posture.dart';

void main() {
  late PrayerGuideModel guide;

  setUpAll(() {
    final raw = File('assets/files/prayer_guide/prayer_guide.json')
        .readAsStringSync();
    guide = PrayerGuideModel.fromJson(
      (jsonDecode(raw) as Map).cast<String, dynamic>(),
    );
  });

  test('parses the bundled guide: intro hadith, overview and 10 steps', () {
    expect(guide.introHadith.text, contains('صَلُّوا'));
    expect(guide.introHadith.source, contains('البخاري'));
    expect(guide.overviewPostures.first, PrayerPosture.standing);
    expect(guide.rakaat.map((r) => r.count), [2, 4, 4, 3, 4]);
    expect(guide.steps, hasLength(10));
  });

  test('every step has a title, a description, postures and evidence', () {
    for (final step in guide.steps) {
      expect(step.title, isNotEmpty);
      expect(step.description, isNotEmpty);
      expect(step.postures, isNotEmpty, reason: step.title);
      expect(step.evidence, isNotEmpty, reason: step.title);
      for (final e in step.evidence) {
        expect(e.text, isNotEmpty);
        expect(e.source, isNotEmpty, reason: 'missing source in ${step.title}');
      }
    }
  });

  test('an unknown posture name fails loudly', () {
    expect(() => parsePostures(['standing', 'flying']), throwsArgumentError);
    expect(() => parsePostures(const []), throwsArgumentError);
  });
}
