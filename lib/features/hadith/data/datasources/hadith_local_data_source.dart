import '../../../../core/error/exceptions.dart';
import '../models/hadith_model.dart';

abstract class HadithLocalDataSource {
  Future<List<HadithModel>> getAllHadiths();
}

class HadithLocalDataSourceImpl implements HadithLocalDataSource {
  @override
  Future<List<HadithModel>> getAllHadiths() async {
    try {
      return _hadiths;
    } catch (e) {
      throw LocalDataException('Failed to load hadiths: $e');
    }
  }

  static const List<HadithModel> _hadiths = [
    HadithModel(
      title: 'إنما الأعمال بالنيات',
      content:
          'عن أمير المؤمنين أبي حفص عمر بن الخطاب رضي الله عنه قال: سمعت رسول الله صلى الله عليه وسلم يقول: "إنما الأعمال بالنيات، وإنما لكل امرئ ما نوى".',
    ),
    HadithModel(
      title: 'من حسن إسلام المرء',
      content:
          'عن أبي هريرة رضي الله عنه قال: قال رسول الله صلى الله عليه وسلم: "من حسن إسلام المرء تركه ما لا يعنيه".',
    ),
    HadithModel(
      title: 'لا يؤمن أحدكم',
      content:
          'عن أبي حمزة أنس بن مالك رضي الله عنه عن النبي صلى الله عليه وسلم قال: "لا يؤمن أحدكم حتى يحب لأخيه ما يحب لنفسه".',
    ),
    HadithModel(
      title: 'الدين النصيحة',
      content:
          'عن أبي رقية تميم بن أوس الداري رضي الله عنه أن النبي صلى الله عليه وسلم قال: "الدين النصيحة". قلنا: لمن؟ قال: "لله ولكتابه ولرسوله ولأئمة المسلمين وعامتهم".',
    ),
    HadithModel(
      title: 'اتق الله حيثما كنت',
      content:
          'عن أبي ذر وأبي عبد الرحمن معاذ بن جبل رضي الله عنهما عن رسول الله صلى الله عليه وسلم قال: "اتق الله حيثما كنت، وأتبع السيئة الحسنة تمحها، وخالق الناس بخلق حسن".',
    ),
  ];
}
