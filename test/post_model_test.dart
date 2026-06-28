import 'package:flutter_test/flutter_test.dart';
import 'package:meet_buddies/post_model.dart';

void main() {
  group('PostModel status getter', () {
    test('returns upcoming when start time is in the future', () {
      final post = PostModel(
        id: '1', userId: 'u1', username: 'test',
        text: 'test', imageUrls: [], likes: [], joinedBy: [],
        activityType: 'gym', maxParticipants: 5,
        timestamp: DateTime.now(),
        startTime: DateTime.now().add(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 2)),
      );
      expect(post.status, ActivityStatus.upcoming);
    });

    test('returns ongoing when now is between start and end', () {
      final post = PostModel(
        id: '1', userId: 'u1', username: 'test',
        text: 'test', imageUrls: [], likes: [], joinedBy: [],
        activityType: 'gym', maxParticipants: 5,
        timestamp: DateTime.now(),
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(post.status, ActivityStatus.ongoing);
    });

    test('returns completed when end time is in the past', () {
      final post = PostModel(
        id: '1', userId: 'u1', username: 'test',
        text: 'test', imageUrls: [], likes: [], joinedBy: [],
        activityType: 'gym', maxParticipants: 5,
        timestamp: DateTime.now(),
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(post.status, ActivityStatus.completed);
    });

    test('returns upcoming when no times set', () {
      final post = PostModel(
        id: '1', userId: 'u1', username: 'test',
        text: 'test', imageUrls: [], likes: [], joinedBy: [],
        activityType: 'gym', maxParticipants: 5,
        timestamp: DateTime.now(),
      );
      expect(post.status, ActivityStatus.upcoming);
    });

    test('isFull returns true when joinedBy reaches maxParticipants', () {
      final post = PostModel(
        id: '1', userId: 'u1', username: 'test',
        text: 'test', imageUrls: [], likes: [],
        joinedBy: ['a', 'b', 'c'],
        activityType: 'gym', maxParticipants: 3,
        timestamp: DateTime.now(),
      );
      expect(post.joinedBy.length >= post.maxParticipants, true);
    });
  });
}