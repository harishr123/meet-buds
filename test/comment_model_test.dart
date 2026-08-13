import 'package:flutter_test/flutter_test.dart';
import 'package:meet_buddies/comment_model.dart';

CommentModel _buildComment({String? replyToId, String? replyToUsername}) {
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

    test(
      'returns true when replyToId is set even if replyToUsername is null',
      () {
        final comment = _buildComment(replyToId: 'c0', replyToUsername: null);
        expect(comment.isReply, isTrue);
      },
    );

    test('returns false when replyToId is null but replyToUsername is set', () {
      final comment = _buildComment(replyToId: null, replyToUsername: 'Alice');
      expect(comment.isReply, isFalse);
    });

    test('returns false when replyToId is an empty string', () {
      final comment = _buildComment(replyToId: '');
      expect(comment.isReply, isTrue);
    });
  });
}
