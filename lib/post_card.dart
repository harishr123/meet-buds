import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_model.dart';
import 'post_service.dart';

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
    final names = await widget.postService
        .getJoinedUsernames(widget.post.joinedBy);
    setState(() {
      _joinedUsernames = names;
      _showJoined = true;
      _loadingJoined = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = widget.post.likes.contains(uid);
    final isJoined = widget.post.joinedBy.contains(uid);
    final isOwner = widget.post.userId == uid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.post.userAvatar != null
                      ? NetworkImage(widget.post.userAvatar!)
                      : null,
                  child: widget.post.userAvatar == null
                      ? Text(widget.post.username[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.post.username,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (widget.post.location != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(widget.post.location!,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                    ],
                  ),
                ),
                Text(
                  _timeAgo(widget.post.timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'delete') {
                        widget.postService.deletePost(widget.post.id);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Text
            if (widget.post.text.isNotEmpty) ...[
              Text(widget.post.text, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 10),
            ],

            // Images
            if (widget.post.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.post.imageUrls.length == 1
                    ? Image.network(widget.post.imageUrls[0],
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover)
                    : SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.post.imageUrls.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 6),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(widget.post.imageUrls[i],
                                width: 260,
                                height: 220,
                                fit: BoxFit.cover),
                          ),
                        ),
                      ),
              ),

            const SizedBox(height: 10),

            // Like + Join buttons
            Row(
              children: [
                // Like
                GestureDetector(
                  onTap: () => widget.postService.toggleLike(widget.post.id),
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(width: 4),
                      Text('${widget.post.likes.length}',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Join button
                GestureDetector(
                  onTap: isOwner ? null : () => widget.postService.toggleJoin(widget.post.id),
                  child: Row(
                    children: [
                      Icon(
                        isJoined ? Icons.group : Icons.group_outlined,
                        color: isOwner ? Colors.grey : (isJoined ? Colors.green : Colors.grey),
                        size: 22,
                      ),
                      const SizedBox(width: 4),
                      Text(isJoined ? 'Joined' : 'Join',
                          style: TextStyle(
                              color: isOwner ? Colors.grey : (isJoined ? Colors.green : Colors.grey))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Joined count — tappable to expand list
                if (widget.post.joinedBy.isNotEmpty)
                  GestureDetector(
                    onTap: _toggleShowJoined,
                    child: _loadingJoined
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            '${widget.post.joinedBy.length} joining ▾',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                  ),
              ],
            ),

            // Joined users list (expanded)
            if (_showJoined && _joinedUsernames.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _joinedUsernames
                    .map((name) => Chip(
                          label: Text(name,
                              style: const TextStyle(fontSize: 12)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
