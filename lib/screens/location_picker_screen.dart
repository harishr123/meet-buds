import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/nus_location.dart';

/// Result returned when the user confirms a pin placement.
class LocationPickResult {
  final String label; // nearest matched location name, shown everywhere else
  final double lat; // exact drop position, for map view precision
  final double lng;

  LocationPickResult({required this.label, required this.lat, required this.lng});
}

class LocationPickerScreen extends StatefulWidget {
  /// Where to drop the pin when the screen opens. Pass the post's existing
  /// coordinates when editing; leave null when creating a new post.
  final LatLng? initialPosition;

  const LocationPickerScreen({super.key, this.initialPosition});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // Default camera position centered roughly on NUS Kent Ridge campus.
  static const LatLng _defaultCenter = LatLng(1.2966, 103.7764);

  late LatLng _pinPosition;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _pinPosition = widget.initialPosition ?? _defaultCenter;
  }

  void _updatePin(LatLng position) {
    setState(() {
      _pinPosition = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    final nearest = NUSLocation.nearestTo(_pinPosition.latitude, _pinPosition.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drop a pin'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.initialPosition ?? _defaultCenter,
                zoom: 16,
              ),
              onMapCreated: (controller) => _mapController = controller,
              onTap: _updatePin,
              markers: {
                Marker(
                  markerId: const MarkerId('activity-pin'),
                  position: _pinPosition,
                  draggable: true,
                  onDragEnd: _updatePin,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place_outlined, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nearest: ${nearest.name}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap or drag the pin to set the exact spot',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      LocationPickResult(
                        label: nearest.name,
                        lat: _pinPosition.latitude,
                        lng: _pinPosition.longitude,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Confirm location'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}