import 'package:flutter/material.dart';
import 'post_service.dart';
import 'post_card.dart';
import 'create_post_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final postService = PostService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Container(
        color: Colors.white,
        child: StreamBuilder(
          stream: postService.getFeed(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.dynamic_feed_outlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No posts yet. Be the first!',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            final posts = snapshot.data!;
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (_, i) => PostCard(
                  key: ValueKey(posts[i].id),
                  post: posts[i],
                  postService: postService),
            );
          },
        ),
      ),
    );
  }
}