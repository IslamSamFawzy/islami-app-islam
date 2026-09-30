import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/mushaf_page.dart';
import '../models/mushaf_models.dart';

/// Reads the Mushaf from the bundled assets (tool/build_mushaf_assets.py).
abstract class MushafLocalDataSource {
  /// Suras, ayat, juz starts and the basmala.
  Future<MushafMetaModel> getMeta();

  /// The lines of page [number], 1-604.
  Future<List<MushafLine>> getPageLines(int number);
}

class MushafLocalDataSourceImpl implements MushafLocalDataSource {
  final AssetBundle bundle;

  /// How many decoded pages to keep: the one on screen, the ones either side
  /// and a few the reader just left.
  final int cacheSize;

  MushafLocalDataSourceImpl({AssetBundle? bundle, this.cacheSize = 12})
    : bundle = bundle ?? rootBundle;

  static const int pageCount = 604;

  Future<MushafMetaModel>? _meta;

  /// Most recently used last. Futures, so two requests for a page share one
  /// load.
  final LinkedHashMap<int, Future<List<MushafLine>>> _pages = LinkedHashMap();

  @override
  Future<MushafMetaModel> getMeta() {
    return _meta ??= _loadMeta().catchError((Object e, StackTrace s) {
      _meta = null; // try again next time
      return Future<MushafMetaModel>.error(e, s);
    });
  }

  Future<MushafMetaModel> _loadMeta() async {
    try {
      final raw = await bundle.loadString(
        'assets/quran/meta.json',
        cache: false,
      );
      // 100 KB of JSON: decoded off the UI thread.
      return await compute(_decodeMeta, raw);
    } catch (e) {
      throw LocalDataException('Failed to load the Mushaf index: $e');
    }
  }

  @override
  Future<List<MushafLine>> getPageLines(int number) {
    if (number < 1 || number > pageCount) {
      return Future.error(LocalDataException('No Mushaf page $number'));
    }
    final cached = _pages.remove(number);
    if (cached != null) {
      _pages[number] = cached;
      return cached;
    }
    final loading = _loadPage(number).catchError((Object e, StackTrace s) {
      _pages.remove(number); // don't keep a failure
      return Future<List<MushafLine>>.error(e, s);
    });
    _pages[number] = loading;
    while (_pages.length > cacheSize) {
      _pages.remove(_pages.keys.first);
    }
    return loading;
  }

  Future<List<MushafLine>> _loadPage(int number) async {
    final meta = await getMeta();
    try {
      final name = number.toString().padLeft(3, '0');
      final raw = await bundle.loadString(
        'assets/quran/pages/$name.json',
        cache: false,
      );
      return await compute(_decodePage, (raw: raw, basmala: meta.basmala));
    } catch (e) {
      throw LocalDataException('Failed to load Mushaf page $number: $e');
    }
  }

  /// Pages currently held, most recently used last. For tests.
  @visibleForTesting
  List<int> get cachedPages => _pages.keys.toList();
}

MushafMetaModel _decodeMeta(String raw) =>
    MushafMetaModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);

List<MushafLine> _decodePage(({String raw, List<String> basmala}) input) =>
    parsePageLines(
      jsonDecode(input.raw) as Map<String, dynamic>,
      input.basmala,
    );
