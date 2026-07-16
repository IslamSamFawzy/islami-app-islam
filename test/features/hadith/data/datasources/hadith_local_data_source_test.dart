import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/hadith/data/datasources/hadith_local_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads all 50 hadiths, first title exact, no stray BOM', () async {
    final ds = HadithLocalDataSourceImpl();
    final hadiths = await ds.getAllHadiths();

    expect(hadiths.length, 50);
    // Verbatim — the space inside "الحد يث" is intentional (matches the Figma).
    expect(hadiths.first.title, 'الحد يث الأول');
    // Both BOMs were stripped.
    expect(hadiths.first.title.codeUnits.contains(0xFEFF), isFalse);
    // Bodies survived.
    expect(hadiths.first.content, isNotEmpty);
    expect(hadiths.last.content, isNotEmpty);
  });
}
