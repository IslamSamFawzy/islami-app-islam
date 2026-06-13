import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../models/sura_model.dart';

/// Contract for the local Quran data source.
abstract class QuranLocalDataSource {
  /// Returns the static list of all 114 suras.
  Future<List<SuraModel>> getAllSuras();

  /// Loads the verses of a sura from its bundled text file.
  Future<List<String>> getSuraVerses(String suraId);

  /// Returns the IDs of recently read suras, most recent first.
  Future<List<String>> getRecentSuraIds();

  /// Records [suraId] as the most recently read sura (deduped, capped).
  Future<void> addRecentSuraId(String suraId);
}

class QuranLocalDataSourceImpl implements QuranLocalDataSource {
  final SharedPreferences sharedPreferences;

  QuranLocalDataSourceImpl({required this.sharedPreferences});

  /// Key under which the recent sura IDs are stored.
  static const String _recentKey = 'recent_sura_ids';

  /// Maximum number of recent suras kept.
  static const int _recentLimit = 10;

  @override
  Future<List<SuraModel>> getAllSuras() async {
    try {
      return _suras;
    } catch (e) {
      throw LocalDataException('Failed to load suras: $e');
    }
  }

  @override
  Future<List<String>> getRecentSuraIds() async {
    try {
      return sharedPreferences.getStringList(_recentKey) ?? <String>[];
    } catch (e) {
      throw LocalDataException('Failed to load recent suras: $e');
    }
  }

  @override
  Future<void> addRecentSuraId(String suraId) async {
    try {
      final current = sharedPreferences.getStringList(_recentKey) ?? <String>[];
      // Move to front, remove duplicates, cap length.
      current.remove(suraId);
      current.insert(0, suraId);
      final capped = current.take(_recentLimit).toList();
      await sharedPreferences.setStringList(_recentKey, capped);
    } catch (e) {
      throw LocalDataException('Failed to save recent sura: $e');
    }
  }

  @override
  Future<List<String>> getSuraVerses(String suraId) async {
    try {
      final content =
          await rootBundle.loadString('assets/files/suras/$suraId.txt');
      return content
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    } catch (e) {
      throw LocalDataException('Failed to load verses for sura $suraId');
    }
  }

  static const List<SuraModel> _suras = [
    SuraModel(id: "1", nameEn: "Al-Fatiha", nameAr: "الفاتحه", ayaCount: "7"),
    SuraModel(id: "2", nameEn: "Al-Baqarah", nameAr: "البقرة", ayaCount: "286"),
    SuraModel(id: "3", nameEn: "Aal-E-Imran", nameAr: "آل عمران", ayaCount: "200"),
    SuraModel(id: "4", nameEn: "An-Nisa'", nameAr: "النساء", ayaCount: "176"),
    SuraModel(id: "5", nameEn: "Al-Ma'idah", nameAr: "المائدة", ayaCount: "120"),
    SuraModel(id: "6", nameEn: "Al-An'am", nameAr: "الأنعام", ayaCount: "165"),
    SuraModel(id: "7", nameEn: "Al-A'raf", nameAr: "الأعراف", ayaCount: "206"),
    SuraModel(id: "8", nameEn: "Al-Anfal", nameAr: "الأنفال", ayaCount: "75"),
    SuraModel(id: "9", nameEn: "At-Tawbah", nameAr: "التوبة", ayaCount: "129"),
    SuraModel(id: "10", nameEn: "Yunus", nameAr: "يونس", ayaCount: "109"),
    SuraModel(id: "11", nameEn: "Hud", nameAr: "هود", ayaCount: "123"),
    SuraModel(id: "12", nameEn: "Yusuf", nameAr: "يوسف", ayaCount: "111"),
    SuraModel(id: "13", nameEn: "Ar-Ra'd", nameAr: "الرعد", ayaCount: "43"),
    SuraModel(id: "14", nameEn: "Ibrahim", nameAr: "إبراهيم", ayaCount: "52"),
    SuraModel(id: "15", nameEn: "Al-Hijr", nameAr: "الحجر", ayaCount: "99"),
    SuraModel(id: "16", nameEn: "An-Nahl", nameAr: "النحل", ayaCount: "128"),
    SuraModel(id: "17", nameEn: "Al-Isra", nameAr: "الإسراء", ayaCount: "111"),
    SuraModel(id: "18", nameEn: "Al-Kahf", nameAr: "الكهف", ayaCount: "110"),
    SuraModel(id: "19", nameEn: "Maryam", nameAr: "مريم", ayaCount: "98"),
    SuraModel(id: "20", nameEn: "Ta-Ha", nameAr: "طه", ayaCount: "135"),
    SuraModel(id: "21", nameEn: "Al-Anbiya", nameAr: "الأنبياء", ayaCount: "112"),
    SuraModel(id: "22", nameEn: "Al-Hajj", nameAr: "الحج", ayaCount: "78"),
    SuraModel(id: "23", nameEn: "Al-Mu'minun", nameAr: "المؤمنون", ayaCount: "118"),
    SuraModel(id: "24", nameEn: "An-Nur", nameAr: "النّور", ayaCount: "64"),
    SuraModel(id: "25", nameEn: "Al-Furqan", nameAr: "الفرقان", ayaCount: "77"),
    SuraModel(id: "26", nameEn: "Ash-Shu'ara", nameAr: "الشعراء", ayaCount: "227"),
    SuraModel(id: "27", nameEn: "An-Naml", nameAr: "النّمل", ayaCount: "93"),
    SuraModel(id: "28", nameEn: "Al-Qasas", nameAr: "القصص", ayaCount: "88"),
    SuraModel(id: "29", nameEn: "Al-Ankabut", nameAr: "العنكبوت", ayaCount: "69"),
    SuraModel(id: "30", nameEn: "Ar-Rum", nameAr: "الرّوم", ayaCount: "60"),
    SuraModel(id: "31", nameEn: "Luqman", nameAr: "لقمان", ayaCount: "34"),
    SuraModel(id: "32", nameEn: "As-Sajda", nameAr: "السجدة", ayaCount: "30"),
    SuraModel(id: "33", nameEn: "Al-Ahzab", nameAr: "الأحزاب", ayaCount: "73"),
    SuraModel(id: "34", nameEn: "Saba", nameAr: "سبأ", ayaCount: "54"),
    SuraModel(id: "35", nameEn: "Fatir", nameAr: "فاطر", ayaCount: "45"),
    SuraModel(id: "36", nameEn: "Ya-Sin", nameAr: "يس", ayaCount: "83"),
    SuraModel(id: "37", nameEn: "As-Saffat", nameAr: "الصافات", ayaCount: "182"),
    SuraModel(id: "38", nameEn: "Sad", nameAr: "ص", ayaCount: "88"),
    SuraModel(id: "39", nameEn: "Az-Zumar", nameAr: "الزمر", ayaCount: "75"),
    SuraModel(id: "40", nameEn: "Ghafir", nameAr: "غافر", ayaCount: "85"),
    SuraModel(id: "41", nameEn: "Fussilat", nameAr: "فصّلت", ayaCount: "54"),
    SuraModel(id: "42", nameEn: "Ash-Shura", nameAr: "الشورى", ayaCount: "53"),
    SuraModel(id: "43", nameEn: "Az-Zukhruf", nameAr: "الزخرف", ayaCount: "89"),
    SuraModel(id: "44", nameEn: "Ad-Dukhan", nameAr: "الدّخان", ayaCount: "59"),
    SuraModel(id: "45", nameEn: "Al-Jathiya", nameAr: "الجاثية", ayaCount: "37"),
    SuraModel(id: "46", nameEn: "Al-Ahqaf", nameAr: "الأحقاف", ayaCount: "35"),
    SuraModel(id: "47", nameEn: "Muhammad", nameAr: "محمد", ayaCount: "38"),
    SuraModel(id: "48", nameEn: "Al-Fath", nameAr: "الفتح", ayaCount: "29"),
    SuraModel(id: "49", nameEn: "Al-Hujurat", nameAr: "الحجرات", ayaCount: "18"),
    SuraModel(id: "50", nameEn: "Qaf", nameAr: "ق", ayaCount: "45"),
    SuraModel(id: "51", nameEn: "Adh-Dhariyat", nameAr: "الذاريات", ayaCount: "60"),
    SuraModel(id: "52", nameEn: "At-Tur", nameAr: "الطور", ayaCount: "49"),
    SuraModel(id: "53", nameEn: "An-Najm", nameAr: "النجم", ayaCount: "62"),
    SuraModel(id: "54", nameEn: "Al-Qamar", nameAr: "القمر", ayaCount: "55"),
    SuraModel(id: "55", nameEn: "Ar-Rahman", nameAr: "الرحمن", ayaCount: "78"),
    SuraModel(id: "56", nameEn: "Al-Waqi'a", nameAr: "الواقعة", ayaCount: "96"),
    SuraModel(id: "57", nameEn: "Al-Hadid", nameAr: "الحديد", ayaCount: "29"),
    SuraModel(id: "58", nameEn: "Al-Mujadila", nameAr: "المجادلة", ayaCount: "22"),
    SuraModel(id: "59", nameEn: "Al-Hashr", nameAr: "الحشر", ayaCount: "24"),
    SuraModel(id: "60", nameEn: "Al-Mumtahina", nameAr: "الممتحنة", ayaCount: "13"),
    SuraModel(id: "61", nameEn: "As-Saff", nameAr: "الصف", ayaCount: "14"),
    SuraModel(id: "62", nameEn: "Al-Jumu'a", nameAr: "الجمعة", ayaCount: "11"),
    SuraModel(id: "63", nameEn: "Al-Munafiqun", nameAr: "المنافقون", ayaCount: "11"),
    SuraModel(id: "64", nameEn: "At-Taghabun", nameAr: "التغابن", ayaCount: "18"),
    SuraModel(id: "65", nameEn: "At-Talaq", nameAr: "الطلاق", ayaCount: "12"),
    SuraModel(id: "66", nameEn: "At-Tahrim", nameAr: "التحريم", ayaCount: "12"),
    SuraModel(id: "67", nameEn: "Al-Mulk", nameAr: "الملك", ayaCount: "30"),
    SuraModel(id: "68", nameEn: "Al-Qalam", nameAr: "القلم", ayaCount: "52"),
    SuraModel(id: "69", nameEn: "Al-Haqqah", nameAr: "الحاقة", ayaCount: "52"),
    SuraModel(id: "70", nameEn: "Al-Ma'arij", nameAr: "المعارج", ayaCount: "44"),
    SuraModel(id: "71", nameEn: "Nuh", nameAr: "نوح", ayaCount: "28"),
    SuraModel(id: "72", nameEn: "Al-Jinn", nameAr: "الجن", ayaCount: "28"),
    SuraModel(id: "73", nameEn: "Al-Muzzammil", nameAr: "المزّمّل", ayaCount: "20"),
    SuraModel(id: "74", nameEn: "Al-Muddathir", nameAr: "المدّثر", ayaCount: "56"),
    SuraModel(id: "75", nameEn: "Al-Qiyamah", nameAr: "القيامة", ayaCount: "40"),
    SuraModel(id: "76", nameEn: "Al-Insan", nameAr: "الإنسان", ayaCount: "31"),
    SuraModel(id: "77", nameEn: "Al-Mursalat", nameAr: "المرسلات", ayaCount: "50"),
    SuraModel(id: "78", nameEn: "An-Naba'", nameAr: "النبأ", ayaCount: "40"),
    SuraModel(id: "79", nameEn: "An-Nazi'at", nameAr: "النازعات", ayaCount: "46"),
    SuraModel(id: "80", nameEn: "Abasa", nameAr: "عبس", ayaCount: "42"),
    SuraModel(id: "81", nameEn: "At-Takwir", nameAr: "التكوير", ayaCount: "29"),
    SuraModel(id: "82", nameEn: "Al-Infitar", nameAr: "الإنفطار", ayaCount: "19"),
    SuraModel(id: "83", nameEn: "Al-Mutaffifin", nameAr: "المطفّفين", ayaCount: "36"),
    SuraModel(id: "84", nameEn: "Al-Inshiqaq", nameAr: "الإنشقاق", ayaCount: "25"),
    SuraModel(id: "85", nameEn: "Al-Buruj", nameAr: "البروج", ayaCount: "22"),
    SuraModel(id: "86", nameEn: "At-Tariq", nameAr: "الطارق", ayaCount: "17"),
    SuraModel(id: "87", nameEn: "Al-A'la", nameAr: "الأعلى", ayaCount: "19"),
    SuraModel(id: "88", nameEn: "Al-Ghashiyah", nameAr: "الغاشية", ayaCount: "26"),
    SuraModel(id: "89", nameEn: "Al-Fajr", nameAr: "الفجر", ayaCount: "30"),
    SuraModel(id: "90", nameEn: "Al-Balad", nameAr: "البلد", ayaCount: "20"),
    SuraModel(id: "91", nameEn: "Ash-Shams", nameAr: "الشمس", ayaCount: "15"),
    SuraModel(id: "92", nameEn: "Al-Lail", nameAr: "الليل", ayaCount: "21"),
    SuraModel(id: "93", nameEn: "Ad-Duha", nameAr: "الضحى", ayaCount: "11"),
    SuraModel(id: "94", nameEn: "Ash-Sharh", nameAr: "الشرح", ayaCount: "8"),
    SuraModel(id: "95", nameEn: "At-Tin", nameAr: "التين", ayaCount: "8"),
    SuraModel(id: "96", nameEn: "Al-Alaq", nameAr: "العلق", ayaCount: "19"),
    SuraModel(id: "97", nameEn: "Al-Qadr", nameAr: "القدر", ayaCount: "5"),
    SuraModel(id: "98", nameEn: "Al-Bayyina", nameAr: "البينة", ayaCount: "8"),
    SuraModel(id: "99", nameEn: "Az-Zalzalah", nameAr: "الزلزلة", ayaCount: "8"),
    SuraModel(id: "100", nameEn: "Al-Adiyat", nameAr: "العاديات", ayaCount: "11"),
    SuraModel(id: "101", nameEn: "Al-Qari'a", nameAr: "القارعة", ayaCount: "11"),
    SuraModel(id: "102", nameEn: "At-Takathur", nameAr: "التكاثر", ayaCount: "8"),
    SuraModel(id: "103", nameEn: "Al-Asr", nameAr: "العصر", ayaCount: "3"),
    SuraModel(id: "104", nameEn: "Al-Humazah", nameAr: "الهمزة", ayaCount: "9"),
    SuraModel(id: "105", nameEn: "Al-Fil", nameAr: "الفيل", ayaCount: "5"),
    SuraModel(id: "106", nameEn: "Quraysh", nameAr: "قريش", ayaCount: "4"),
    SuraModel(id: "107", nameEn: "Al-Ma'un", nameAr: "الماعون", ayaCount: "7"),
    SuraModel(id: "108", nameEn: "Al-Kawthar", nameAr: "الكوثر", ayaCount: "3"),
    SuraModel(id: "109", nameEn: "Al-Kafirun", nameAr: "الكافرون", ayaCount: "6"),
    SuraModel(id: "110", nameEn: "An-Nasr", nameAr: "النصر", ayaCount: "3"),
    SuraModel(id: "111", nameEn: "Al-Masad", nameAr: "المسد", ayaCount: "5"),
    SuraModel(id: "112", nameEn: "Al-Ikhlas", nameAr: "الإخلاص", ayaCount: "4"),
    SuraModel(id: "113", nameEn: "Al-Falaq", nameAr: "الفلق", ayaCount: "5"),
    SuraModel(id: "114", nameEn: "An-Nas", nameAr: "الناس", ayaCount: "6"),
  ];
}
