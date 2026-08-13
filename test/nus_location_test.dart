import 'package:flutter_test/flutter_test.dart';
import 'package:meet_buddies/models/nus_location.dart';

void main() {
  group('NUSLocation.nearestTo', () {
    test('returns the exact location when given its own coordinates', () {
      final result = NUSLocation.nearestTo(1.2966, 103.7731);
      expect(result.name, 'Central Library');
    });

    test('every location resolves to itself at its own coordinates', () {
      for (final loc in NUSLocation.all) {
        final result = NUSLocation.nearestTo(loc.lat, loc.lng);
        expect(
          result.name,
          loc.name,
          reason: '${loc.name} did not resolve to itself',
        );
      }
    });

    test('a small offset still resolves to the nearest location', () {
      // ~20m north-east of Kent Ridge Hall, well inside its catchment.
      final result = NUSLocation.nearestTo(1.2920, 103.7749);
      expect(result.name, 'Kent Ridge Hall');
    });

    test('a coordinate far off campus still returns a known location', () {
      final result = NUSLocation.nearestTo(1.3644, 103.9915); // Changi
      expect(NUSLocation.all.map((l) => l.name), contains(result.name));
    });

    test('handles the equator and prime meridian without throwing', () {
      final result = NUSLocation.nearestTo(0, 0);
      expect(result, isNotNull);
    });

    test('is deterministic for the same input', () {
      final a = NUSLocation.nearestTo(1.2990, 103.7750);
      final b = NUSLocation.nearestTo(1.2990, 103.7750);
      expect(a.name, b.name);
    });
  });

  group('NUSLocation.all', () {
    test('is not empty', () {
      expect(NUSLocation.all, isNotEmpty);
    });

    test('has no duplicate names', () {
      final names = NUSLocation.all.map((l) => l.name).toList();
      expect(names.toSet().length, names.length);
    });

    test('all coordinates fall within Singapore bounds', () {
      for (final loc in NUSLocation.all) {
        expect(loc.lat, inInclusiveRange(1.15, 1.48), reason: loc.name);
        expect(loc.lng, inInclusiveRange(103.6, 104.1), reason: loc.name);
      }
    });
  });
}
