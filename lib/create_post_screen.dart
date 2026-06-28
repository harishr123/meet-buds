import 'package:flutter/material.dart';
import 'post_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textController = TextEditingController();
  final _locationController = TextEditingController();
  final _postService = PostService();
  bool _loading = false;
  String _selectedActivity = 'general';
  int _maxParticipants = 0; // 0 = no limit

  static const _activities = [
    {'type': 'gym', 'label': 'Gym', 'emoji': '🏋️'},
    {'type': 'food', 'label': 'Food', 'emoji': '🍜'},
    {'type': 'study', 'label': 'Study', 'emoji': '📚'},
    {'type': 'sports', 'label': 'Sports', 'emoji': '⚽'},
    {'type': 'hangout', 'label': 'Hangout', 'emoji': '☕'},
    {'type': 'general', 'label': 'Other', 'emoji': '📌'},
  ];

  Future<void> _submit() async {
    if (_textController.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await _postService.createPost(
        text: _textController.text.trim(),
        images: [],
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        activityType: _selectedActivity,
        maxParticipants: _maxParticipants,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        actions: [
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _submit,
                  child: const Text('Post',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity type picker
            const Text('Activity type',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _activities.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final a = _activities[i];
                  final selected = _selectedActivity == a['type'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedActivity = a['type']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? _activityColor(_selectedActivity)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: selected
                              ? _activityBorderColor(_selectedActivity)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(a['emoji']!,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(a['label']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: selected
                                    ? _activityTextColor(_selectedActivity)
                                    : Colors.grey.shade700,
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Post text
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "What's happening? Where are you going?",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Location
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'Add location (optional)',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Max participants
            const Text('Max participants',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _maxParticipants.toDouble(),
                    min: 0,
                    max: 20,
                    divisions: 20,
                    label: _maxParticipants == 0
                        ? 'No limit'
                        : '$_maxParticipants',
                    onChanged: (val) =>
                        setState(() => _maxParticipants = val.toInt()),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    _maxParticipants == 0 ? 'No limit' : '$_maxParticipants people',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _activityColor(String type) {
    switch (type) {
      case 'gym': return const Color(0xFFE1F5EE);
      case 'food': return const Color(0xFFFAECE7);
      case 'study': return const Color(0xFFE6F1FB);
      case 'sports': return const Color(0xFFEAF3DE);
      case 'hangout': return const Color(0xFFFAEEDA);
      default: return const Color(0xFFEEEDFE);
    }
  }

  Color _activityBorderColor(String type) {
    switch (type) {
      case 'gym': return const Color(0xFF1D9E75);
      case 'food': return const Color(0xFFD85A30);
      case 'study': return const Color(0xFF378ADD);
      case 'sports': return const Color(0xFF639922);
      case 'hangout': return const Color(0xFFBA7517);
      default: return const Color(0xFF7F77DD);
    }
  }

  Color _activityTextColor(String type) {
    switch (type) {
      case 'gym': return const Color(0xFF085041);
      case 'food': return const Color(0xFF993C1D);
      case 'study': return const Color(0xFF0C447C);
      case 'sports': return const Color(0xFF3B6D11);
      case 'hangout': return const Color(0xFF854F0B);
      default: return const Color(0xFF3C3489);
    }
  }
}
