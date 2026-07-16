/// The canonical list of the 114 suras (number, English name, Arabic name and
/// aya count), shared across features so Quran, Radio and Downloads all resolve
/// the same names from a sura number.
///
/// Pure Dart — no Flutter imports — so it stays testable and usable anywhere.
/// Data copied verbatim from the Quran feature's former private list.
class SuraName {
  final int number;
  final String nameEn;
  final String nameAr;
  final int ayaCount;

  const SuraName({
    required this.number,
    required this.nameEn,
    required this.nameAr,
    required this.ayaCount,
  });
}

abstract class SuraNames {
  /// All 114 suras, in order (index 0 → sura 1).
  static const List<SuraName> all = [
    SuraName(number: 1, nameEn: "Al-Fatiha", nameAr: "الفاتحه", ayaCount: 7),
    SuraName(number: 2, nameEn: "Al-Baqarah", nameAr: "البقرة", ayaCount: 286),
    SuraName(number: 3, nameEn: "Aal-E-Imran", nameAr: "آل عمران", ayaCount: 200),
    SuraName(number: 4, nameEn: "An-Nisa'", nameAr: "النساء", ayaCount: 176),
    SuraName(number: 5, nameEn: "Al-Ma'idah", nameAr: "المائدة", ayaCount: 120),
    SuraName(number: 6, nameEn: "Al-An'am", nameAr: "الأنعام", ayaCount: 165),
    SuraName(number: 7, nameEn: "Al-A'raf", nameAr: "الأعراف", ayaCount: 206),
    SuraName(number: 8, nameEn: "Al-Anfal", nameAr: "الأنفال", ayaCount: 75),
    SuraName(number: 9, nameEn: "At-Tawbah", nameAr: "التوبة", ayaCount: 129),
    SuraName(number: 10, nameEn: "Yunus", nameAr: "يونس", ayaCount: 109),
    SuraName(number: 11, nameEn: "Hud", nameAr: "هود", ayaCount: 123),
    SuraName(number: 12, nameEn: "Yusuf", nameAr: "يوسف", ayaCount: 111),
    SuraName(number: 13, nameEn: "Ar-Ra'd", nameAr: "الرعد", ayaCount: 43),
    SuraName(number: 14, nameEn: "Ibrahim", nameAr: "إبراهيم", ayaCount: 52),
    SuraName(number: 15, nameEn: "Al-Hijr", nameAr: "الحجر", ayaCount: 99),
    SuraName(number: 16, nameEn: "An-Nahl", nameAr: "النحل", ayaCount: 128),
    SuraName(number: 17, nameEn: "Al-Isra", nameAr: "الإسراء", ayaCount: 111),
    SuraName(number: 18, nameEn: "Al-Kahf", nameAr: "الكهف", ayaCount: 110),
    SuraName(number: 19, nameEn: "Maryam", nameAr: "مريم", ayaCount: 98),
    SuraName(number: 20, nameEn: "Ta-Ha", nameAr: "طه", ayaCount: 135),
    SuraName(number: 21, nameEn: "Al-Anbiya", nameAr: "الأنبياء", ayaCount: 112),
    SuraName(number: 22, nameEn: "Al-Hajj", nameAr: "الحج", ayaCount: 78),
    SuraName(number: 23, nameEn: "Al-Mu'minun", nameAr: "المؤمنون", ayaCount: 118),
    SuraName(number: 24, nameEn: "An-Nur", nameAr: "النّور", ayaCount: 64),
    SuraName(number: 25, nameEn: "Al-Furqan", nameAr: "الفرقان", ayaCount: 77),
    SuraName(number: 26, nameEn: "Ash-Shu'ara", nameAr: "الشعراء", ayaCount: 227),
    SuraName(number: 27, nameEn: "An-Naml", nameAr: "النّمل", ayaCount: 93),
    SuraName(number: 28, nameEn: "Al-Qasas", nameAr: "القصص", ayaCount: 88),
    SuraName(number: 29, nameEn: "Al-Ankabut", nameAr: "العنكبوت", ayaCount: 69),
    SuraName(number: 30, nameEn: "Ar-Rum", nameAr: "الرّوم", ayaCount: 60),
    SuraName(number: 31, nameEn: "Luqman", nameAr: "لقمان", ayaCount: 34),
    SuraName(number: 32, nameEn: "As-Sajda", nameAr: "السجدة", ayaCount: 30),
    SuraName(number: 33, nameEn: "Al-Ahzab", nameAr: "الأحزاب", ayaCount: 73),
    SuraName(number: 34, nameEn: "Saba", nameAr: "سبأ", ayaCount: 54),
    SuraName(number: 35, nameEn: "Fatir", nameAr: "فاطر", ayaCount: 45),
    SuraName(number: 36, nameEn: "Ya-Sin", nameAr: "يس", ayaCount: 83),
    SuraName(number: 37, nameEn: "As-Saffat", nameAr: "الصافات", ayaCount: 182),
    SuraName(number: 38, nameEn: "Sad", nameAr: "ص", ayaCount: 88),
    SuraName(number: 39, nameEn: "Az-Zumar", nameAr: "الزمر", ayaCount: 75),
    SuraName(number: 40, nameEn: "Ghafir", nameAr: "غافر", ayaCount: 85),
    SuraName(number: 41, nameEn: "Fussilat", nameAr: "فصّلت", ayaCount: 54),
    SuraName(number: 42, nameEn: "Ash-Shura", nameAr: "الشورى", ayaCount: 53),
    SuraName(number: 43, nameEn: "Az-Zukhruf", nameAr: "الزخرف", ayaCount: 89),
    SuraName(number: 44, nameEn: "Ad-Dukhan", nameAr: "الدّخان", ayaCount: 59),
    SuraName(number: 45, nameEn: "Al-Jathiya", nameAr: "الجاثية", ayaCount: 37),
    SuraName(number: 46, nameEn: "Al-Ahqaf", nameAr: "الأحقاف", ayaCount: 35),
    SuraName(number: 47, nameEn: "Muhammad", nameAr: "محمد", ayaCount: 38),
    SuraName(number: 48, nameEn: "Al-Fath", nameAr: "الفتح", ayaCount: 29),
    SuraName(number: 49, nameEn: "Al-Hujurat", nameAr: "الحجرات", ayaCount: 18),
    SuraName(number: 50, nameEn: "Qaf", nameAr: "ق", ayaCount: 45),
    SuraName(number: 51, nameEn: "Adh-Dhariyat", nameAr: "الذاريات", ayaCount: 60),
    SuraName(number: 52, nameEn: "At-Tur", nameAr: "الطور", ayaCount: 49),
    SuraName(number: 53, nameEn: "An-Najm", nameAr: "النجم", ayaCount: 62),
    SuraName(number: 54, nameEn: "Al-Qamar", nameAr: "القمر", ayaCount: 55),
    SuraName(number: 55, nameEn: "Ar-Rahman", nameAr: "الرحمن", ayaCount: 78),
    SuraName(number: 56, nameEn: "Al-Waqi'a", nameAr: "الواقعة", ayaCount: 96),
    SuraName(number: 57, nameEn: "Al-Hadid", nameAr: "الحديد", ayaCount: 29),
    SuraName(number: 58, nameEn: "Al-Mujadila", nameAr: "المجادلة", ayaCount: 22),
    SuraName(number: 59, nameEn: "Al-Hashr", nameAr: "الحشر", ayaCount: 24),
    SuraName(number: 60, nameEn: "Al-Mumtahina", nameAr: "الممتحنة", ayaCount: 13),
    SuraName(number: 61, nameEn: "As-Saff", nameAr: "الصف", ayaCount: 14),
    SuraName(number: 62, nameEn: "Al-Jumu'a", nameAr: "الجمعة", ayaCount: 11),
    SuraName(number: 63, nameEn: "Al-Munafiqun", nameAr: "المنافقون", ayaCount: 11),
    SuraName(number: 64, nameEn: "At-Taghabun", nameAr: "التغابن", ayaCount: 18),
    SuraName(number: 65, nameEn: "At-Talaq", nameAr: "الطلاق", ayaCount: 12),
    SuraName(number: 66, nameEn: "At-Tahrim", nameAr: "التحريم", ayaCount: 12),
    SuraName(number: 67, nameEn: "Al-Mulk", nameAr: "الملك", ayaCount: 30),
    SuraName(number: 68, nameEn: "Al-Qalam", nameAr: "القلم", ayaCount: 52),
    SuraName(number: 69, nameEn: "Al-Haqqah", nameAr: "الحاقة", ayaCount: 52),
    SuraName(number: 70, nameEn: "Al-Ma'arij", nameAr: "المعارج", ayaCount: 44),
    SuraName(number: 71, nameEn: "Nuh", nameAr: "نوح", ayaCount: 28),
    SuraName(number: 72, nameEn: "Al-Jinn", nameAr: "الجن", ayaCount: 28),
    SuraName(number: 73, nameEn: "Al-Muzzammil", nameAr: "المزّمّل", ayaCount: 20),
    SuraName(number: 74, nameEn: "Al-Muddathir", nameAr: "المدّثر", ayaCount: 56),
    SuraName(number: 75, nameEn: "Al-Qiyamah", nameAr: "القيامة", ayaCount: 40),
    SuraName(number: 76, nameEn: "Al-Insan", nameAr: "الإنسان", ayaCount: 31),
    SuraName(number: 77, nameEn: "Al-Mursalat", nameAr: "المرسلات", ayaCount: 50),
    SuraName(number: 78, nameEn: "An-Naba'", nameAr: "النبأ", ayaCount: 40),
    SuraName(number: 79, nameEn: "An-Nazi'at", nameAr: "النازعات", ayaCount: 46),
    SuraName(number: 80, nameEn: "Abasa", nameAr: "عبس", ayaCount: 42),
    SuraName(number: 81, nameEn: "At-Takwir", nameAr: "التكوير", ayaCount: 29),
    SuraName(number: 82, nameEn: "Al-Infitar", nameAr: "الإنفطار", ayaCount: 19),
    SuraName(number: 83, nameEn: "Al-Mutaffifin", nameAr: "المطفّفين", ayaCount: 36),
    SuraName(number: 84, nameEn: "Al-Inshiqaq", nameAr: "الإنشقاق", ayaCount: 25),
    SuraName(number: 85, nameEn: "Al-Buruj", nameAr: "البروج", ayaCount: 22),
    SuraName(number: 86, nameEn: "At-Tariq", nameAr: "الطارق", ayaCount: 17),
    SuraName(number: 87, nameEn: "Al-A'la", nameAr: "الأعلى", ayaCount: 19),
    SuraName(number: 88, nameEn: "Al-Ghashiyah", nameAr: "الغاشية", ayaCount: 26),
    SuraName(number: 89, nameEn: "Al-Fajr", nameAr: "الفجر", ayaCount: 30),
    SuraName(number: 90, nameEn: "Al-Balad", nameAr: "البلد", ayaCount: 20),
    SuraName(number: 91, nameEn: "Ash-Shams", nameAr: "الشمس", ayaCount: 15),
    SuraName(number: 92, nameEn: "Al-Lail", nameAr: "الليل", ayaCount: 21),
    SuraName(number: 93, nameEn: "Ad-Duha", nameAr: "الضحى", ayaCount: 11),
    SuraName(number: 94, nameEn: "Ash-Sharh", nameAr: "الشرح", ayaCount: 8),
    SuraName(number: 95, nameEn: "At-Tin", nameAr: "التين", ayaCount: 8),
    SuraName(number: 96, nameEn: "Al-Alaq", nameAr: "العلق", ayaCount: 19),
    SuraName(number: 97, nameEn: "Al-Qadr", nameAr: "القدر", ayaCount: 5),
    SuraName(number: 98, nameEn: "Al-Bayyina", nameAr: "البينة", ayaCount: 8),
    SuraName(number: 99, nameEn: "Az-Zalzalah", nameAr: "الزلزلة", ayaCount: 8),
    SuraName(number: 100, nameEn: "Al-Adiyat", nameAr: "العاديات", ayaCount: 11),
    SuraName(number: 101, nameEn: "Al-Qari'a", nameAr: "القارعة", ayaCount: 11),
    SuraName(number: 102, nameEn: "At-Takathur", nameAr: "التكاثر", ayaCount: 8),
    SuraName(number: 103, nameEn: "Al-Asr", nameAr: "العصر", ayaCount: 3),
    SuraName(number: 104, nameEn: "Al-Humazah", nameAr: "الهمزة", ayaCount: 9),
    SuraName(number: 105, nameEn: "Al-Fil", nameAr: "الفيل", ayaCount: 5),
    SuraName(number: 106, nameEn: "Quraysh", nameAr: "قريش", ayaCount: 4),
    SuraName(number: 107, nameEn: "Al-Ma'un", nameAr: "الماعون", ayaCount: 7),
    SuraName(number: 108, nameEn: "Al-Kawthar", nameAr: "الكوثر", ayaCount: 3),
    SuraName(number: 109, nameEn: "Al-Kafirun", nameAr: "الكافرون", ayaCount: 6),
    SuraName(number: 110, nameEn: "An-Nasr", nameAr: "النصر", ayaCount: 3),
    SuraName(number: 111, nameEn: "Al-Masad", nameAr: "المسد", ayaCount: 5),
    SuraName(number: 112, nameEn: "Al-Ikhlas", nameAr: "الإخلاص", ayaCount: 4),
    SuraName(number: 113, nameEn: "Al-Falaq", nameAr: "الفلق", ayaCount: 5),
    SuraName(number: 114, nameEn: "An-Nas", nameAr: "الناس", ayaCount: 6),
  ];

  /// Lazily-built number → entry index so lookups are O(1) (the reciter screen
  /// renders up to 114 rows, each resolving a name).
  static final Map<int, SuraName> _byNumber = {
    for (final s in all) s.number: s,
  };

  /// The entry for sura [n] (1–114), or `null` when out of range.
  static SuraName? byNumber(int n) {
    if (n < 1 || n > 114) return null;
    return _byNumber[n];
  }
}
