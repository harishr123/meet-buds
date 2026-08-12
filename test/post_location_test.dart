import 'package:flutter_test/flutter_test.dart';
import 'package:meet_buddies/post_model.dart';

PostModel buildPost({double? lat, double? lng}) {
  return PostModel(
    id: '1',
    userId: 'u1',
    username: 'test',
    text: 'test',
    imageUrls: [],
    likes: [],
    joinedBy: [],
    activityType: 'general',
    maxParticipants: 0,
    timestamp: DateTime.now(),
    locationLat: lat,
    locationLng: lng,
  );
}

void main() {
  group('PostModel.hasLocationPin', () {
    test('is false when both coordinates are null', () {
      expect(buildPost().hasLocationPin, isFalse);
    });

    test('is false when only latitude is set', () {
      expect(buildPost(lat: 1.2966).hasLocationPin, isFalse);
    });

    test('is false when only longitude is set', () {
      expect(buildPost(lng: 103.7764).hasLocationPin, isFalse);
    });

    test('is true when both coordinates are set', () {
      expect(buildPost(lat: 1.2966, lng: 103.7764).hasLocationPin, isTrue);
    });

    test('treats zero coordinates as a valid pin', () {
      expect(buildPost(lat: 0, lng: 0).hasLocationPin, isTrue);
    });
  });
}
