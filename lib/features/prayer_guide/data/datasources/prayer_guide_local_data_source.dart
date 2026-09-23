import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/error/exceptions.dart';
import '../models/prayer_guide_model.dart';

abstract class PrayerGuideLocalDataSource {
  Future<PrayerGuideModel> getPrayerGuide();
}

class PrayerGuideLocalDataSourceImpl implements PrayerGuideLocalDataSource {
  static const String assetPath = 'assets/files/prayer_guide/prayer_guide.json';

  final AssetBundle _bundle;

  PrayerGuideLocalDataSourceImpl({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  @override
  Future<PrayerGuideModel> getPrayerGuide() async {
    try {
      final raw = await _bundle.loadString(assetPath);
      final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
      return PrayerGuideModel.fromJson(json);
    } catch (e) {
      throw LocalDataException('Failed to load the prayer guide: $e');
    }
  }
}
