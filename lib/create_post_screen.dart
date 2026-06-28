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
  int _maxParticipants = 2;
  DateTime? _startTime;
  DateTime? _endTime;
  String _errorMessage = '';

  static const _activities = [
    {'type': 'gym', 'label': 'Gym', 'emoji': '🏋️'},
    {'type': 'food', 'label': 'Food', 'emoji': '🍜'},
    {'type': 'study', 'label': 'Study', 'emoji': '📚'},
    {'type': 'sports', 'label': 'Sports', 'emoji': '⚽'},
    {'type': 'hangout', 'label': 'Hangout', 'emoji': '☕'},
    {'type': 'general', 'label': 'Other', 'emoji': '📌'},
  ];

  Future<void> _pickTime({required bool isStart}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
      _errorMessage = '';
    });
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Set time';
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    final location = _locationController.text.trim();

    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please describe your activity.');
      return;
    }
    if (location.isEmpty) {
      setState(() => _errorMessage = 'Please add a location.');
      return;
    }
    if (_startTime == null) {
      setState(() => _errorMessage = 'Please set a start time.');
      return;
    }
    if (_endTime == null) {
      setState(() => _errorMessage = 'Please set an end time.');
      return;
    }
    if (_endTime!.isBefore(_startTime!)) {
      setState(() => _errorMessage = 'End time must be after start time.');
      return;
    }

    setState(() { _loading = true; _errorMessage = ''; });
    try {
      await _postService.createPost(
        text: text,
        images: [],
        location: location,
        activityType: _selectedActivity,
        maxParticipants: _maxParticipants,
        startTime: _startTime,
        endTime: _endTime,
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    onTap: () => setState(() => _selectedActivity = a['type']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                          Text(a['emoji']!, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(a['label']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
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

            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "What's happening? Where are you going?",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _errorMessage = ''),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'Location (required)',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _errorMessage = ''),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isStart: true),
                    icon: Icon(Icons.access_time, size: 16,
                        color: _startTime == null ? Colors.grey : const Color(0xFF1D9E75)),
                    label: Text(
                      _startTime == null ? 'Start time (required)' : _formatTime(_startTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: _startTime == null ? Colors.grey : const Color(0xFF1D9E75),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isStart: false),
                    icon: Icon(Icons.access_time, size: 16,
                        color: _endTime == null ? Colors.grey : const Color(0xFF1D9E75)),
                    label: Text(
                      _endTime == null ? 'End time (required)' : _formatTime(_endTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: _endTime == null ? Colors.grey : const Color(0xFF1D9E75),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text('Max participants',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _maxParticipants.toDouble(),
                    min: 2,
                    max: 20,
                    divisions: 18,
                    label: '$_maxParticipants',
                    onChanged: (val) => setState(() => _maxParticipants = val.toInt()),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    '$_maxParticipants people',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEBEB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Color(0xFFA32D2D)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage,
                          style: const TextStyle(color: Color(0xFFA32D2D), fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
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