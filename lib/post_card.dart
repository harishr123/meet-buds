import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_model.dart';
import 'post_service.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final PostService postService;

  const PostCard({super.key, required this.post, required this.postService});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = post.likes.contains(uid);
    final isOwner = post.userId == uid;

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
                  backgroundImage: post.userAvatar != null
                      ? NetworkImage(post.userAvatar!)
                      : null,
                  child: post.userAvatar == null
                      ? Text(post.username[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.username,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (post.location != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(post.location!,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                    ],
                  ),
                ),
                Text(
                  _timeAgo(post.timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'delete') postService.deletePost(post.id);
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
            if (post.text.isNotEmpty) ...[
              Text(post.text, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 10),
            ],

            // Images
            if (post.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: post.imageUrls.length == 1
                    ? Image.network(post.imageUrls[0],
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover)
                    : SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: post.imageUrls.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 6),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(post.imageUrls[i],
                                width: 260,
                                height: 220,
                                fit: BoxFit.cover),
                          ),
                        ),
                      ),
              ),

            const SizedBox(height: 10),

            // Like button
            Row(
              children: [
                GestureDetector(
                  onTap: () => postService.toggleLike(post.id),
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(width: 4),
                      Text('${post.likes.length}',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
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
