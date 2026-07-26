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
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // Default camera position centered roughly on NUS Kent Ridge campus.
  static const LatLng _defaultCenter = LatLng(1.2966, 103.7764);

  LatLng _pinPosition = _defaultCenter;
  GoogleMapController? _mapController;

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
              initialCameraPosition: const CameraPosition(
                target: _defaultCenter,
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
                  color: Colors.black.withOpacity(0.05),
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
