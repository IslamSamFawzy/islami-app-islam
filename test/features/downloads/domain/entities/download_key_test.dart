import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/downloads/domain/entities/download_key.dart';

void main() {
  test('renders as <reciterId>/<suraId>', () {
    expect(
      const DownloadKey(reciterId: '112', suraId: '2').toString(),
      '112/2',
    );
  });

  test('parse round-trips the stored form', () {
    const key = DownloadKey(reciterId: '112', suraId: '2');

    expect(DownloadKey.parse(key.toString()), key);
  });

  test('parse survives a malformed key', () {
    expect(
      DownloadKey.parse('112'),
      const DownloadKey(reciterId: '112', suraId: ''),
    );
    expect(
      DownloadKey.parse(''),
      const DownloadKey(reciterId: '', suraId: ''),
    );
  });

  test('equal keys are interchangeable as map keys', () {
    final byKey = {
      const DownloadKey(reciterId: '1', suraId: '2'): 'entry',
    };

    expect(byKey[const DownloadKey(reciterId: '1', suraId: '2')], 'entry');
    expect(byKey[DownloadKey.parse('1/2')], 'entry');
  });
}
