import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'post_model.dart';
import 'post_card.dart';
import 'post_service.dart';
import 'screens/post_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  static const LatLng _campusCenter = LatLng(1.2966, 103.7764);
  final _postService = PostService();
  final Map<String, BitmapDescriptor> _iconCache = {};

  bool _mapFailed = false;
  bool _mapReady = false;

  /// Marker styling per activity type. Colours match the category badge
  /// colours used on the post cards so the map and feed stay consistent.
  static const Map<String, (IconData, Color)> _categoryStyle = {
    'gym': (Icons.fitness_center, Color(0xFF0F6E56)),
    'food': (Icons.restaurant, Color(0xFFD85A30)),
    'study': (Icons.menu_book, Color(0xFF185FA5)),
    'sports': (Icons.sports_soccer, Color(0xFF639922)),
    'hangout': (Icons.local_cafe, Color(0xFFBA7517)),
    'general': (Icons.push_pin, Color(0xFF534AB7)),
  };

  @override
  void initState() {
    super.initState();
    _startMapTimeout();
  }

  /// If onMapCreated never fires, the maps SDK failed to initialise
  /// (no network, bad key, plugin not registered). Show a fallback.
  void _startMapTimeout() {
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && !_mapReady) {
        setState(() => _mapFailed = true);
      }
    });
  }

  void _retryMap() {
    setState(() {
      _mapFailed = false;
      _mapReady = false;
    });
    _startMapTimeout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activities Map')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorState(
              icon: Icons.cloud_off,
              title: 'Could not load activities',
              message:
                  'Something went wrong fetching activities. Check your connection and try again.',
              onRetry: () => setState(() {}),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .where((post) => post.hasLocationPin)
              .where((post) => post.status != ActivityStatus.completed)
              .toList();

          // Group posts that share (near-)identical coordinates.
          final Map<String, List<PostModel>> grouped = {};
          for (final post in posts) {
            final key =
                '${post.locationLat!.toStringAsFixed(5)}_${post.locationLng!.toStringAsFixed(5)}';
            grouped.putIfAbsent(key, () => []).add(post);
          }

          if (_mapFailed) {
            return _errorState(
              icon: Icons.map_outlined,
              title: 'Map unavailable',
              message:
                  'We could not load the campus map. Check your connection and try again.',
              onRetry: _retryMap,
              showFeedHint: true,
            );
          }

          return FutureBuilder<Set<Marker>>(
            future: _buildMarkers(grouped),
            builder: (context, markerSnapshot) {
              if (!markerSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _campusCenter,
                      zoom: 15.5,
                    ),
                    markers: markerSnapshot.data!,
                    onMapCreated: (_) {
                      if (mounted && !_mapReady) {
                        setState(() => _mapReady = true);
                      }
                    },
                  ),
                  if (posts.isEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 24,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            'No activities on the map right now',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _errorState({
    required IconData icon,
    required String title,
    required String message,
    required VoidCallback onRetry,
    bool showFeedHint = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
            ),
            if (showFeedHint) ...[
              const SizedBox(height: 6),
              Text(
                'You can still browse activities from the Feed tab.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<Set<Marker>> _buildMarkers(
    Map<String, List<PostModel>> grouped,
  ) async {
    final markers = <Marker>{};
    for (final entry in grouped.entries) {
      final group = entry.value;
      final first = group.first;
      final icon = await _iconFor(first.activityType, group.length);

      markers.add(
        Marker(
          markerId: MarkerId(entry.key),
          position: LatLng(first.locationLat!, first.locationLng!),
          icon: icon,
          onTap: () {
            if (group.length == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(post: group.first),
                ),
              );
            } else {
              _showLocationSheet(context, group);
            }
          },
        ),
      );
    }
    return markers;
  }

  Future<BitmapDescriptor> _iconFor(String category, int count) async {
    final key = '${category}_$count';
    final cached = _iconCache[key];
    if (cached != null) return cached;

    final style = _categoryStyle[category] ?? _categoryStyle['general']!;
    final built = await _buildMarkerBitmap(
      icon: style.$1,
      color: style.$2,
      count: count,
    );
    _iconCache[key] = built;
    return built;
  }

  Future<BitmapDescriptor> _buildMarkerBitmap({
    required IconData icon,
    required Color color,
    required int count,
    double pixelRatio = 3.0,
  }) async {
    final size = 44 * pixelRatio;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final radius = size / 2 - 3 * pixelRatio;

    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius - 2.5 * pixelRatio,
      Paint()..color = color,
    );

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 20 * pixelRatio,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      center - Offset(iconPainter.width / 2, iconPainter.height / 2),
    );

    if (count > 1) {
      final badgeCenter = Offset(size - 8 * pixelRatio, 8 * pixelRatio);
      canvas.drawCircle(
        badgeCenter,
        9 * pixelRatio,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        badgeCenter,
        8 * pixelRatio,
        Paint()..color = const Color(0xFFD85A30),
      );
      final countPainter = TextPainter(
        text: TextSpan(
          text: '$count',
          style: TextStyle(
            fontSize: 11 * pixelRatio,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      countPainter.paint(
        canvas,
        badgeCenter - Offset(countPainter.width / 2, countPainter.height / 2),
      );
    }

    final img = await recorder.endRecording().toImage(size.ceil(), size.ceil());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
    );
  }

  void _showLocationSheet(BuildContext context, List<PostModel> group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView.builder(
            controller: controller,
            padding: const EdgeInsets.all(12),
            itemCount: group.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PostCard(post: group[i], postService: _postService),
            ),
          ),
        ),
      ),
    );
  }
}
