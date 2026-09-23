import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/utils/formatters.dart';

void main() {
  group('formatBytes', () {
    test('uses the largest fitting unit', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(-5), '0 B');
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
      expect(formatBytes(3 * 1024 * 1024 * 1024), '3.0 GB');
    });

    test('drops the decimal from 10 upwards, and past the largest unit', () {
      expect(formatBytes(20 * 1024), '20 KB');
      expect(formatBytes(5 * 1024 * 1024 * 1024 * 1024), '5120 GB');
    });
  });

  group('formatThousands', () {
    test('groups in threes and keeps the sign', () {
      expect(formatThousands(0), '0');
      expect(formatThousands(999), '999');
      expect(formatThousands(1234), '1,234');
      expect(formatThousands(1234567), '1,234,567');
      expect(formatThousands(-1234), '-1,234');
    });
  });

  group('toArabicDigits', () {
    test('maps every digit', () {
      expect(toArabicDigits(0), '٠');
      expect(toArabicDigits(7), '٧');
      expect(toArabicDigits(12), '١٢');
      expect(toArabicDigits(1023456789), '١٠٢٣٤٥٦٧٨٩');
    });
  });

  group('formatCountdown', () {
    test('formats as HH:MM and clamps the past to zero', () {
      expect(formatCountdown(Duration.zero), '00:00');
      expect(formatCountdown(const Duration(minutes: 5)), '00:05');
      expect(formatCountdown(const Duration(hours: 2, minutes: 7)), '02:07');
      expect(formatCountdown(const Duration(hours: 26)), '26:00');
      expect(formatCountdown(const Duration(minutes: -30)), '00:00');
    });
  });
}
