import 'package:flutter/services.dart';

import '../../../../core/error/exceptions.dart';
import '../models/hadith_model.dart';

abstract class HadithLocalDataSource {
  Future<List<HadithModel>> getAllHadiths();
}

class HadithLocalDataSourceImpl implements HadithLocalDataSource {
  /// The 50 bundled hadith files, h1.txt … h50.txt.
  static const int _count = 50;
  static const String _dir = 'assets/files/hadeeth';

  /// Reads all 50 hadiths in file order (1→50). The files are small, so they
  /// are loaded in parallel. Any missing/unreadable file fails the whole load
  /// (a [LocalDataException]) rather than silently showing fewer hadiths.
  @override
  Future<List<HadithModel>> getAllHadiths() async {
    try {
      // Indices, not a glob: sort by the integer so h10 follows h9, not h1.
      final futures = List.generate(_count, (i) => _loadHadith(i + 1));
      return await Future.wait(futures);
    } catch (e) {
      throw LocalDataException('Failed to load hadiths: $e');
    }
  }

  Future<HadithModel> _loadHadith(int number) async {
    final raw = await rootBundle.loadString('$_dir/h$number.txt');

    // Normalise line endings only (not the Arabic), then strip EVERY leading
    // BOM — h1.txt has a double BOM, and one left in place shows as a stray
    // glyph before the title.
    final text = _stripLeadingBoms(
      raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n'),
    );

    final lines = text.split('\n');
    final title = lines.first.trim();
    // Body = every line after the title, joined verbatim so paragraph breaks
    // survive; only leading/trailing blank lines are trimmed.
    final content = lines.skip(1).join('\n').trim();

    return HadithModel(title: title, content: content);
  }

  /// Removes all leading U+FEFF (BOM) code units.
  String _stripLeadingBoms(String s) {
    var i = 0;
    while (i < s.length && s.codeUnitAt(i) == 0xFEFF) {
      i++;
    }
    return i == 0 ? s : s.substring(i);
  }
}
