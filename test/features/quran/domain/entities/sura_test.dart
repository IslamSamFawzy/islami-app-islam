import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/quran/domain/entities/sura.dart';

Sura _sura(int id) => Sura(id: id, nameEn: '', nameAr: '', ayaCount: 1);

void main() {
  group('Sura.opensWithBasmala', () {
    test('Al-Fatiha has no header: the basmala is its first ayah', () {
      expect(_sura(1).opensWithBasmala, isFalse);
    });

    test('At-Tawba has no basmala', () {
      expect(_sura(9).opensWithBasmala, isFalse);
    });

    test('every other sura opens with it', () {
      final others = [for (var id = 1; id <= 114; id++) id]
        ..removeWhere((id) => id == 1 || id == 9);
      expect(others.every((id) => _sura(id).opensWithBasmala), isTrue);
    });
  });
}
