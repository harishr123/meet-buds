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

  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _pinPosition = widget.initialPosition ?? _defaultCenter;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Named campus locations matching the current search text.
  List<NUSLocation> get _results {
    if (_query.trim().isEmpty) return const [];
    final q = _query.trim().toLowerCase();
    return NUSLocation.all
        .where((l) => l.name.toLowerCase().contains(q))
        .toList();
  }

  void _updatePin(LatLng position) {
    setState(() {
      _pinPosition = position;
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _query = '');
  }

  /// Jump the pin and the camera to a searched location.
  void _selectLocation(NUSLocation loc) {
    final target = LatLng(loc.lat, loc.lng);
    _searchCtrl.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _query = '';
      _pinPosition = target;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 17));
  }

  @override
  Widget build(BuildContext context) {
    final nearest =
        NUSLocation.nearestTo(_pinPosition.latitude, _pinPosition.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drop a pin'),
      ),
      body: Column(
        children: [
          // Search field sits ABOVE the map rather than floating over it.
          // On web the GoogleMap is an HTML platform view that swallows
          // pointer events from any Flutter widget drawn on top of it —
          // pointer_interceptor works around this in Chrome but not in
          // Safari. Keeping the field outside the Stack sidesteps the
          // problem entirely, on every browser.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search for a place on campus',
                      hintStyle: TextStyle(
                          fontSize: 14, color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search,
                          size: 20, color: Colors.grey.shade400),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(Icons.clear,
                                  size: 18, color: Colors.grey.shade400),
                              onPressed: _clearSearch,
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                if (_query.trim().isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _results.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Text(
                              'No campus locations match that. '
                              'You can still tap or drag the pin.',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade500),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _results.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                            ),
                            itemBuilder: (context, i) {
                              final loc = _results[i];
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.place_outlined,
                                    size: 20, color: Colors.grey.shade500),
                                title: Text(loc.name,
                                    style: const TextStyle(fontSize: 14)),
                                onTap: () => _selectLocation(loc),
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.initialPosition ?? _defaultCenter,
                zoom: 16,
              ),
              onMapCreated: (controller) => _mapController = controller,
              onTap: (pos) {
                // Tapping the map is an explicit choice, so drop any
                // in-progress search rather than leaving results open.
                FocusScope.of(context).unfocus();
                _clearSearch();
                _updatePin(pos);
              },
              markers: {
                Marker(
                  markerId: const MarkerId('activity-pin'),
                  position: _pinPosition,
                  draggable: true,
                  onDragEnd: _updatePin,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
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
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Search, tap or drag the pin to set the exact spot',
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