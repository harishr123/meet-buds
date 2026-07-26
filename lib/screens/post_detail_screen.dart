import 'package:flutter/material.dart';
import '../post_model.dart';
import '../post_card.dart';
import '../post_service.dart';

class PostDetailScreen extends StatelessWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: PostCard(post: post, postService: PostService()),
      ),
    );
  }
}