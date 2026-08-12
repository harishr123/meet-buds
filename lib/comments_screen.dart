import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'comment_model.dart';
import 'post_service.dart';

/// Shows a scrollable bottom sheet with the comments for [postId].
Future<void> showCommentsSheet({
  required BuildContext context,
  required String postId,
  required PostService postService,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CommentsSheet(postId: postId, postService: postService),
  );
}

class CommentsSheet extends StatefulWidget {
  final String postId;
  final PostService postService;

  const CommentsSheet({
    super.key,
    required this.postId,
    required this.postService,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _sending = false;

  // Set when the user taps "Reply" on a comment. Null = plain top-level comment.
  CommentModel? _replyingTo;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startReply(CommentModel c) {
    setState(() => _replyingTo = c);
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final replying = _replyingTo;
      await widget.postService.addComment(
        widget.postId,
        text,
        // Flatten reply-to-a-reply so it still nests under the original
        // top-level comment, but keep the @mention of who was replied to.
        replyToId: replying == null
            ? null
            : (replying.isReply ? replying.replyToId : replying.id),
        replyToUsername: replying?.username,
      );
      _controller.clear();
      setState(() => _replyingTo = null);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  Widget _commentTile(
    CommentModel c, {
    required bool isReply,
    required String? uid,
  }) {
    final isOwner = c.userId == uid;
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 34 : 0, top: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isReply ? 24 : 30,
            height: isReply ? 24 : 30,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                c.username.isNotEmpty ? c.username[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: isReply ? 11 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      c.username,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _timeAgo(c.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: Colors.black87,
                    ),
                    children: [
                      if (c.replyToUsername != null)
                        TextSpan(
                          text: '@${c.replyToUsername} ',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade400,
                          ),
                        ),
                      TextSpan(text: c.text),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _startReply(c),
                  child: Text(
                    'Reply',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isOwner)
            GestureDetector(
              onTap: () =>
                  widget.postService.deleteComment(widget.postId, c.id),
              child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Comments',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<CommentModel>>(
                stream: widget.postService.getComments(widget.postId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final comments = snapshot.data ?? [];
                  if (comments.isEmpty) {
                    return Center(
                      child: Text(
                        'No comments yet. Say something!',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }

                  // Group replies under their top-level parent.
                  final topLevel = comments.where((c) => !c.isReply).toList();
                  final repliesByParent = <String, List<CommentModel>>{};
                  for (final c in comments.where((c) => c.isReply)) {
                    repliesByParent.putIfAbsent(c.replyToId!, () => []).add(c);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: topLevel.length,
                    itemBuilder: (_, i) {
                      final parent = topLevel[i];
                      final replies = repliesByParent[parent.id] ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _commentTile(parent, isReply: false, uid: uid),
                          for (final r in replies)
                            _commentTile(r, isReply: true, uid: uid),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            if (_replyingTo != null)
              Container(
                width: double.infinity,
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Replying to @${_replyingTo!.username}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _cancelReply,
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: _replyingTo == null
                            ? 'Add a comment...'
                            : 'Reply to @${_replyingTo!.username}...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _sending
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          onPressed: _send,
                          icon: const Icon(Icons.send),
                          color: Theme.of(context).primaryColor,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
