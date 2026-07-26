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

  static const Map<String, (IconData, Color)> _categoryStyle = {
    'football': (Icons.sports_soccer, Color(0xFF639922)),
    'study':    (Icons.menu_book, Color(0xFF378ADD)),
    'food':     (Icons.restaurant, Color(0xFFEF9F27)),
    'general':  (Icons.groups, Color(0xFF5F5E5A)),
  };

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
            return Center(child: Text('Error loading map: ${snapshot.error}'));
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

          return FutureBuilder<Set<Marker>>(
            future: _buildMarkers(grouped),
            builder: (context, markerSnapshot) {
              if (!markerSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _campusCenter,
                  zoom: 15.5,
                ),
                markers: markerSnapshot.data!,
              );
            },
          );
        },
      ),
    );
  }

  Future<Set<Marker>> _buildMarkers(Map<String, List<PostModel>> grouped) async {
    final markers = <Marker>{};
    for (final entry in grouped.entries) {
      final group = entry.value;
      final first = group.first;
      final icon = await _iconFor(first.activityType, group.length);

      markers.add(Marker(
        markerId: MarkerId(entry.key),
        position: LatLng(first.locationLat!, first.locationLng!),
        icon: icon,
        onTap: () {
          if (group.length == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PostDetailScreen(post: group.first)),
            );
          } else {
            _showLocationSheet(context, group);
          }
        },
      ));
    }
    return markers;
  }

  Future<BitmapDescriptor> _iconFor(String category, int count) async {
    final key = '${category}_$count';
    final cached = _iconCache[key];
    if (cached != null) return cached;

    final style = _categoryStyle[category] ?? _categoryStyle['general']!;
    final built = await _buildMarkerBitmap(icon: style.$1, color: style.$2, count: count);
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
    canvas.drawCircle(center, radius - 2.5 * pixelRatio, Paint()..color = color);

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
      canvas.drawCircle(badgeCenter, 9 * pixelRatio, Paint()..color = Colors.white);
      canvas.drawCircle(badgeCenter, 8 * pixelRatio, Paint()..color = const Color(0xFFD85A30));
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
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: pixelRatio);
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