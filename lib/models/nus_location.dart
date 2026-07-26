import 'dart:math';

class NUSLocation {
  final String name;
  final double lat;
  final double lng;

  const NUSLocation({required this.name, required this.lat, required this.lng});

  // Coordinates verified against Google Maps place data (July 2026).
  static const List<NUSLocation> all = [
    NUSLocation(name: 'UTown Gym', lat: 1.3045, lng: 103.7725),
    NUSLocation(name: 'UTown Green', lat: 1.3049, lng: 103.7732),
    NUSLocation(name: 'Yusof Ishak House', lat: 1.2985, lng: 103.7749),
    NUSLocation(name: 'UTown Flavours', lat: 1.3044, lng: 103.7730),
    NUSLocation(name: 'UTown Fine Food', lat: 1.3040, lng: 103.7735),
    NUSLocation(name: 'Central Library', lat: 1.2965, lng: 103.7731),
    NUSLocation(name: 'The Deck (FASS)', lat: 1.2944, lng: 103.7726),
    NUSLocation(name: 'Techno Edge (CDE)', lat: 1.2979, lng: 103.7717),
    NUSLocation(name: 'Terrace (Computing)', lat: 1.2944, lng: 103.7743),
    NUSLocation(name: 'COM1/COM2', lat: 1.2952, lng: 103.7738),
    NUSLocation(name: 'University Sports Centre', lat: 1.2998, lng: 103.7755),
    NUSLocation(name: 'MPSH', lat: 1.3008, lng: 103.7760),
    NUSLocation(name: 'PGP Foodcourt', lat: 1.2913, lng: 103.7802),
    NUSLocation(name: 'PGP', lat: 1.2904, lng: 103.7807),
    NUSLocation(name: 'Kent Ridge Hall', lat: 1.2918, lng: 103.7748),
    NUSLocation(name: 'RC4', lat: 1.3082, lng: 103.7734),
    NUSLocation(name: 'University Cultural Centre', lat: 1.3016, lng: 103.7722),
  ];

  /// Finds the nearest predefined location to an arbitrary dropped pin
  /// using the Haversine formula (great-circle distance in meters).
  static NUSLocation nearestTo(double lat, double lng) {
    NUSLocation closest = all.first;
    double closestDist = double.infinity;
    for (final loc in all) {
      final dist = _haversineMeters(lat, lng, loc.lat, loc.lng);
      if (dist < closestDist) {
        closestDist = dist;
        closest = loc;
      }
    }
    return closest;
  }

  static double _haversineMeters(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180);
}
