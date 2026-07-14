import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/downloads/data/models/download_entry_model.dart';

void main() {
  test('DownloadEntryModel round-trips through toJson/fromJson', () {
    final model = DownloadEntryModel(
      reciterId: '5',
      suraId: '2',
      path: '/data/audio/5/2.mp3',
      bytes: 1234567,
      downloadedAt: DateTime(2026, 7, 14, 10, 30),
    );

    expect(DownloadEntryModel.fromJson(model.toJson()), model);
  });
}
