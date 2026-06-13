import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/azkar.dart';
import '../models/azkar_model.dart';

abstract class AzkarLocalDataSource {
  Future<AzkarCollectionModel> getAzkar(AzkarType type);
}

class AzkarLocalDataSourceImpl implements AzkarLocalDataSource {
  @override
  Future<AzkarCollectionModel> getAzkar(AzkarType type) async {
    final fileName = type == AzkarType.morning ? 'morning' : 'evening';
    try {
      final raw =
          await rootBundle.loadString('assets/files/azkar/$fileName.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AzkarCollectionModel.fromJson(json);
    } catch (e) {
      throw LocalDataException('Failed to load $fileName azkar: $e');
    }
  }
}
