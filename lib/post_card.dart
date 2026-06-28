import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_model.dart';
import 'post_service.dart';
import 'screens/profile_screen.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final PostService postService;

  const PostCard({super.key, required this.post, required this.postService});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _showJoined = false;
  List<String> _joinedUsernames = [];
  bool _loadingJoined = false;

  Future<void> _toggleShowJoined() async {
    if (_showJoined) {
      setState(() => _showJoined = false);
      return;
    }
    setState(() => _loadingJoined = true);
    final names = await widget.postService.getJoinedUsernames(widget.post.joinedBy);
    setState(() {
      _joinedUsernames = names;
      _showJoined = true;
      _loadingJoined = false;
    });
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: widget.post.userId),
      ),
    );
  }

  void _showEditDialog() {
    final textCtrl = TextEditingController(text: widget.post.text);
    final locCtrl = TextEditingController(text: widget.post.location ?? '');
    DateTime? startTime = widget.post.startTime;
    DateTime? endTime = widget.post.endTime;

    String formatTime(DateTime? dt) {
      if (dt == null) return 'Set time';
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Post'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Text',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: startTime ?? now,
                            firstDate: now.subtract(const Duration(days: 1)),
                            lastDate: now.add(const Duration(days: 365)),
                          );
                          if (date == null) return;
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: startTime != null
                                ? TimeOfDay.fromDateTime(startTime!)
                                : TimeOfDay.now(),
                          );
                          if (time == null) return;
                          setDialogState(() {
                            startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          });
                        },
                        icon: const Icon(Icons.access_time, size: 14),
                        label: Text(formatTime(startTime), style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: endTime ?? now,
                            firstDate: now.subtract(const Duration(days: 1)),
                            lastDate: now.add(const Duration(days: 365)),
                          );
                          if (date == null) return;
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: endTime != null
                                ? TimeOfDay.fromDateTime(endTime!)
                                : TimeOfDay.now(),
                          );
                          if (time == null) return;
                          setDialogState(() {
                            endTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          });
                        },
                        icon: const Icon(Icons.access_time, size: 14),
                        label: Text(formatTime(endTime), style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await widget.postService.updatePost(
                  postId: widget.post.id,
                  newText: textCtrl.text.trim(),
                  newLocation: locCtrl.text.trim().isEmpty ? null : locCtrl.text.trim(),
                  newStartTime: startTime,
                  newEndTime: endTime,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _activityConfig(String type) {
    switch (type) {
      case 'gym':
        return {
          'gradient': [const Color(0xFFE1F5EE), const Color(0xFF9FE1CB)],
          'text': const Color(0xFF085041),
          'badge': const Color(0xFF0F6E56),
          'emoji': '🏋️',
          'label': 'Gym',
        };
      case 'food':
        return {
          'gradient': [const Color(0xFFFAECE7), const Color(0xFFF5C4B3)],
          'text': const Color(0xFF993C1D),
          'badge': const Color(0xFFD85A30),
          'emoji': '🍜',
          'label': 'Food',
        };
      case 'study':
        return {
          'gradient': [const Color(0xFFE6F1FB), const Color(0xFFB5D4F4)],
          'text': const Color(0xFF0C447C),
          'badge': const Color(0xFF185FA5),
          'emoji': '📚',
          'label': 'Study',
        };
      case 'sports':
        return {
          'gradient': [const Color(0xFFEAF3DE), const Color(0xFFC0DD97)],
          'text': const Color(0xFF3B6D11),
          'badge': const Color(0xFF639922),
          'emoji': '⚽',
          'label': 'Sports',
        };
      case 'hangout':
        return {
          'gradient': [const Color(0xFFFAEEDA), const Color(0xFFFAC775)],
          'text': const Color(0xFF854F0B),
          'badge': const Color(0xFFBA7517),
          'emoji': '☕',
          'label': 'Hangout',
        };
      default:
        return {
          'gradient': [const Color(0xFFEEEDFE), const Color(0xFFCECBF6)],
          'text': const Color(0xFF3C3489),
          'badge': const Color(0xFF534AB7),
          'emoji': '📌',
          'label': 'General',
        };
    }
  }

  Widget _statusBadge(ActivityStatus status) {
    Color color;
    String label;
    IconData icon;
    switch (status) {
      case ActivityStatus.ongoing:
        color = const Color(0xFF1D9E75);
        label = 'Ongoing';
        icon = Icons.circle;
        break;
      case ActivityStatus.upcoming:
        color = const Color(0xFF185FA5);
        label = 'Upcoming';
        icon = Icons.schedule;
        break;
      case ActivityStatus.completed:
        color = Colors.grey.shade500;
        label = 'Completed';
        icon = Icons.check_circle_outline;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = widget.post.likes.contains(uid);
    final isJoined = widget.post.joinedBy.contains(uid);
    final isOwner = widget.post.userId == uid;
    final username = widget.post.username;
    final config = _activityConfig(widget.post.activityType);
    final gradientColors = config['gradient'] as List<Color>;
    final headerText = config['text'] as Color;
    final badgeColor = config['badge'] as Color;
    final joinedCount = widget.post.joinedBy.length;
    final maxP = widget.post.maxParticipants;
    final isFull = maxP > 0 && joinedCount >= maxP;
    final spotsLeft = maxP > 0 ? maxP - joinedCount : null;
    final hasTime = widget.post.startTime != null && widget.post.endTime != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Tappable avatar + username
                GestureDetector(
                  onTap: _openProfile,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            username[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: headerText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(username,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: headerText)),
                          if (widget.post.location != null)
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 11, color: headerText.withOpacity(0.7)),
                                const SizedBox(width: 2),
                                Text(widget.post.location!,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: headerText.withOpacity(0.7))),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Activity badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    children: [
                      Text(config['emoji'] as String,
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(config['label'] as String,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: badgeColor)),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Text(_timeAgo(widget.post.timestamp),
                    style: TextStyle(
                        fontSize: 11, color: headerText.withOpacity(0.7))),
                if (isOwner)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, size: 18, color: headerText),
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showEditDialog();
                      } else if (val == 'delete') {
                        widget.postService.deletePost(widget.post.id);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge + time row
                if (hasTime) ...[
                  Row(
                    children: [
                      _statusBadge(widget.post.status),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatDateTime(widget.post.startTime!)} – ${_formatDateTime(widget.post.endTime!)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                if (widget.post.text.isNotEmpty)
                  Text(widget.post.text,
                      style: const TextStyle(fontSize: 15, height: 1.45)),

                if (widget.post.imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: widget.post.imageUrls.length == 1
                        ? Image.network(widget.post.imageUrls[0],
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover)
                        : SizedBox(
                            height: 200,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.post.imageUrls.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 6),
                              itemBuilder: (_, i) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                    widget.post.imageUrls[i],
                                    width: 240,
                                    height: 200,
                                    fit: BoxFit.cover),
                              ),
                            ),
                          ),
                  ),
                ],

                const SizedBox(height: 12),

                if (maxP > 0) ...[
                  Row(
                    children: [
                      Icon(
                        isFull ? Icons.block : Icons.people_outline,
                        size: 13,
                        color: isFull ? Colors.red.shade400 : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFull
                            ? 'Activity full'
                            : '$spotsLeft spot${spotsLeft == 1 ? '' : 's'} left',
                        style: TextStyle(
                          fontSize: 12,
                          color: isFull ? Colors.red.shade400 : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Action buttons
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => widget.postService.toggleLike(widget.post.id),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 19,
                            color: isLiked ? const Color(0xFFD4537E) : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 5),
                          Text('${widget.post.likes.length}',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: (isOwner || isFull)
                          ? null
                          : () => widget.postService.toggleJoin(widget.post.id),
                      child: Row(
                        children: [
                          Icon(
                            isJoined ? Icons.group : Icons.group_outlined,
                            size: 19,
                            color: isOwner
                                ? Colors.grey.shade300
                                : isFull && !isJoined
                                    ? Colors.grey.shade300
                                    : isJoined
                                        ? const Color(0xFF1D9E75)
                                        : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isOwner
                                ? 'Your post'
                                : isFull && !isJoined
                                    ? 'Full'
                                    : isJoined
                                        ? 'Joined'
                                        : 'Join',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isJoined ? FontWeight.w500 : FontWeight.normal,
                              color: isOwner
                                  ? Colors.grey.shade300
                                  : isFull && !isJoined
                                      ? Colors.grey.shade300
                                      : isJoined
                                          ? const Color(0xFF1D9E75)
                                          : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (joinedCount > 0)
                      GestureDetector(
                        onTap: _toggleShowJoined,
                        child: _loadingJoined
                            ? SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5, color: Colors.grey.shade400),
                              )
                            : Text(
                                '$joinedCount joining ${_showJoined ? '▴' : '▾'}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ),
                  ],
                ),

                if (_showJoined && _joinedUsernames.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _joinedUsernames
                        .map((name) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: gradientColors[0],
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(name,
                                  style: TextStyle(fontSize: 12, color: headerText)),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}