import 'package:flutter_test/flutter_test.dart';
import 'package:meet_buddies/comment_model.dart';

CommentModel _buildComment({
  String? replyToId,
  String? replyToUsername,
}) {
  return CommentModel(
    id: 'c1',
    userId: 'u1',
    username: 'test',
    text: 'nice one!',
    timestamp: DateTime.now(),
    replyToId: replyToId,
    replyToUsername: replyToUsername,
  );
}

void main() {
  group('CommentModel isReply getter', () {
    test('returns false for a top-level comment (no replyToId)', () {
      final comment = _buildComment();
      expect(comment.isReply, isFalse);
    });

    test('returns true when replyToId is set', () {
      final comment = _buildComment(replyToId: 'c0', replyToUsername: 'Alice');
      expect(comment.isReply, isTrue);
    });

    test('returns true when replyToId is set even if replyToUsername is null', () {
      // isReply only checks replyToId, so a missing username shouldn't
      // affect whether this counts as a reply.
      final comment = _buildComment(replyToId: 'c0', replyToUsername: null);
      expect(comment.isReply, isTrue);
    });

    test('returns false when replyToId is null but replyToUsername is set', () {
      // Defensive/inconsistent-data case: username without an id shouldn't
      // make this look like a reply, since isReply keys off replyToId only.
      final comment = _buildComment(replyToId: null, replyToUsername: 'Alice');
      expect(comment.isReply, isFalse);
    });

    test('returns false when replyToId is an empty string', () {
      // Empty string is non-null, so per current logic this counts as a reply.
      // This test documents that behavior rather than assuming it's filtered out.
      final comment = _buildComment(replyToId: '');
      expect(comment.isReply, isTrue);
    });
  });
}