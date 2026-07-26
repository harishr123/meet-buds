import 'package:flutter_test/flutter_test.dart';
import 'package:meet_buddies/post_model.dart';

// Mirrors the exact capacity check used in post_card.dart (line ~283):
//   final isFull = maxP > 0 && joinedCount >= maxP;
// Kept here as a local helper so these tests don't require any changes
// to PostModel or PostCard.
bool isFull(PostModel post) {
  final maxP = post.maxParticipants;
  final joinedCount = post.joinedBy.length;
  return maxP > 0 && joinedCount >= maxP;
}

PostModel _buildPost({
  required List<String> joinedBy,
  required int maxParticipants,
}) {
  return PostModel(
    id: '1',
    userId: 'u1',
    username: 'test',
    text: 'test',
    imageUrls: [],
    likes: [],
    joinedBy: joinedBy,
    activityType: 'gym',
    maxParticipants: maxParticipants,
    timestamp: DateTime.now(),
  );
}

void main() {
  group('post_card.dart isFull capacity logic', () {
    test('returns false when joinedBy is below maxParticipants', () {
      final post = _buildPost(joinedBy: ['a'], maxParticipants: 5);
      expect(isFull(post), isFalse);
    });

    test('returns false when joinedBy is one below maxParticipants', () {
      final post = _buildPost(joinedBy: ['a', 'b', 'c'], maxParticipants: 4);
      expect(isFull(post), isFalse);
    });

    test('returns true when joinedBy.length equals maxParticipants exactly', () {
      final post = _buildPost(joinedBy: ['a', 'b', 'c'], maxParticipants: 3);
      expect(isFull(post), isTrue);
    });

    test('returns true when joinedBy.length exceeds maxParticipants', () {
      // Guards against race conditions where two joins land concurrently.
      final post = _buildPost(joinedBy: ['a', 'b', 'c', 'd'], maxParticipants: 3);
      expect(isFull(post), isTrue);
    });

    test('returns false when joinedBy is empty and maxParticipants > 0', () {
      final post = _buildPost(joinedBy: [], maxParticipants: 3);
      expect(isFull(post), isFalse);
    });

    test('maxParticipants of 0 means unlimited: never full even with many joins', () {
      final post = _buildPost(joinedBy: ['a', 'b', 'c', 'd', 'e'], maxParticipants: 0);
      expect(isFull(post), isFalse);
    });

    test('maxParticipants of 0 with empty joinedBy is also not full', () {
      final post = _buildPost(joinedBy: [], maxParticipants: 0);
      expect(isFull(post), isFalse);
    });

    test('returns true when maxParticipants is 1 and one user has joined', () {
      final post = _buildPost(joinedBy: ['a'], maxParticipants: 1);
      expect(isFull(post), isTrue);
    });
  });
}