import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/utils/qibla_calculator.dart';

// Expected bearings were verified by running the calculator (not taken from the
// brief on faith): the brief's "~245°" for Riyadh actually computes to 243.8°
// for the coordinates used here, so that is what we assert.
void main() {
  group('qiblaBearing', () {
    test('Cairo points south-east toward Mecca (~136°)', () {
      final bearing =
          QiblaCalculator.qiblaBearing(latitude: 30.0444, longitude: 31.2357);
      expect(bearing, closeTo(136.14, 0.5));
      expect(QiblaCalculator.cardinal(bearing), 'SE');
    });

    test('Jakarta points north-west toward Mecca (~295°)', () {
      final bearing =
          QiblaCalculator.qiblaBearing(latitude: -6.2, longitude: 106.8);
      expect(bearing, closeTo(295.16, 0.5));
      expect(QiblaCalculator.cardinal(bearing), 'NW');
    });

    test('Riyadh points south-west toward Mecca (~244°)', () {
      final bearing =
          QiblaCalculator.qiblaBearing(latitude: 24.7136, longitude: 46.6753);
      expect(bearing, closeTo(243.80, 0.5));
      expect(QiblaCalculator.cardinal(bearing), 'SW');
    });

    test('is always normalised to [0, 360)', () {
      for (final coord in const [
        [40.7128, -74.0060], // New York
        [51.5074, -0.1278], // London
        [-33.8688, 151.2093], // Sydney
        [64.1466, -21.9426], // Reykjavik
      ]) {
        final b = QiblaCalculator.qiblaBearing(
            latitude: coord[0], longitude: coord[1]);
        expect(b, greaterThanOrEqualTo(0));
        expect(b, lessThan(360));
        expect(b.isFinite, isTrue);
      }
    });

    group('edge cases', () {
      test('at the Kaaba itself the direction degenerates to 0', () {
        final bearing = QiblaCalculator.qiblaBearing(
          latitude: QiblaCalculator.kaabaLat,
          longitude: QiblaCalculator.kaabaLng,
        );
        expect(bearing, 0);
      });

      test('at the antipode the bearing is finite and in range', () {
        // Antipodal point of the Kaaba.
        final bearing = QiblaCalculator.qiblaBearing(
          latitude: -QiblaCalculator.kaabaLat,
          longitude: QiblaCalculator.kaabaLng - 180,
        );
        expect(bearing.isFinite, isTrue);
        expect(bearing, greaterThanOrEqualTo(0));
        expect(bearing, lessThan(360));
      });

      test('is continuous across the ±180° meridian (no wrap glitch)', () {
        // Two points 0.2° of longitude apart, straddling the antimeridian.
        final east =
            QiblaCalculator.qiblaBearing(latitude: 0, longitude: 179.9);
        final west =
            QiblaCalculator.qiblaBearing(latitude: 0, longitude: -179.9);

        expect(east, inInclusiveRange(0, 360));
        expect(west, inInclusiveRange(0, 360));
        // Nearly-identical inputs give nearly-identical bearings.
        expect((east - west).abs(), lessThan(0.5));
      });
    });
  });

  group('distanceToKaabaKm', () {
    test('Cairo is ~1287 km from Mecca', () {
      final d = QiblaCalculator.distanceToKaabaKm(
          latitude: 30.0444, longitude: 31.2357);
      expect(d, closeTo(1287.2, 2));
    });

    test('is zero at the Kaaba', () {
      final d = QiblaCalculator.distanceToKaabaKm(
        latitude: QiblaCalculator.kaabaLat,
        longitude: QiblaCalculator.kaabaLng,
      );
      expect(d, closeTo(0, 0.001));
    });

    test('is half the Earth\'s circumference at the antipode', () {
      final d = QiblaCalculator.distanceToKaabaKm(
        latitude: -QiblaCalculator.kaabaLat,
        longitude: QiblaCalculator.kaabaLng - 180,
      );
      // π · R for R = 6371 km ≈ 20015 km.
      expect(d, closeTo(20015.1, 2));
    });
  });

  group('cardinal', () {
    test('maps the 8 principal directions', () {
      expect(QiblaCalculator.cardinal(0), 'N');
      expect(QiblaCalculator.cardinal(45), 'NE');
      expect(QiblaCalculator.cardinal(90), 'E');
      expect(QiblaCalculator.cardinal(135), 'SE');
      expect(QiblaCalculator.cardinal(180), 'S');
      expect(QiblaCalculator.cardinal(225), 'SW');
      expect(QiblaCalculator.cardinal(270), 'W');
      expect(QiblaCalculator.cardinal(315), 'NW');
    });

    test('rounds to the nearest sector and wraps at 360°', () {
      expect(QiblaCalculator.cardinal(359), 'N');
      expect(QiblaCalculator.cardinal(360), 'N');
      expect(QiblaCalculator.cardinal(22), 'N');
      expect(QiblaCalculator.cardinal(23), 'NE');
      expect(QiblaCalculator.cardinal(-45), 'NW'); // negative wraps
    });
  });
}
