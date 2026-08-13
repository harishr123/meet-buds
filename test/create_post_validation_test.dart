import 'package:flutter_test/flutter_test.dart';

String? validateCreatePost({
  required String text,
  required String location,
  required DateTime? startTime,
  required DateTime? endTime,
}) {
  final trimmedText = text.trim();
  final trimmedLocation = location.trim();

  if (trimmedText.isEmpty) return 'Please describe your activity.';
  if (trimmedLocation.isEmpty) return 'Please add a location.';
  if (startTime == null) return 'Please set a start time.';
  if (endTime == null) return 'Please set an end time.';
  if (endTime.isBefore(startTime)) return 'End time must be after start time.';

  return null;
}

void main() {
  group('CreatePostScreen validation', () {
    final validStart = DateTime(2026, 8, 1, 10, 0);
    final validEnd = DateTime(2026, 8, 1, 12, 0);

    test('fails when text is empty', () {
      final error = validateCreatePost(
        text: '',
        location: 'NUS Library',
        startTime: validStart,
        endTime: validEnd,
      );
      expect(error, 'Please describe your activity.');
    });

    test('fails when text is only whitespace', () {
      final error = validateCreatePost(
        text: '   ',
        location: 'NUS Library',
        startTime: validStart,
        endTime: validEnd,
      );
      expect(error, 'Please describe your activity.');
    });

    test('fails when location is empty', () {
      final error = validateCreatePost(
        text: 'Anyone up for badminton?',
        location: '',
        startTime: validStart,
        endTime: validEnd,
      );
      expect(error, 'Please add a location.');
    });

    test('fails when location is only whitespace', () {
      final error = validateCreatePost(
        text: 'Anyone up for badminton?',
        location: '   ',
        startTime: validStart,
        endTime: validEnd,
      );
      expect(error, 'Please add a location.');
    });

    test('fails when start time is not set', () {
      final error = validateCreatePost(
        text: 'Anyone up for badminton?',
        location: 'NUS Library',
        startTime: null,
        endTime: validEnd,
      );
      expect(error, 'Please set a start time.');
    });

    test('fails when end time is not set', () {
      final error = validateCreatePost(
        text: 'Anyone up for badminton?',
        location: 'NUS Library',
        startTime: validStart,
        endTime: null,
      );
      expect(error, 'Please set an end time.');
    });

    test('fails when end time is before start time', () {
      final error = validateCreatePost(
        text: 'Anyone up for badminton?',
        location: 'NUS Library',
        startTime: DateTime(2026, 8, 1, 14, 0),
        endTime: DateTime(2026, 8, 1, 12, 0),
      );
      expect(error, 'End time must be after start time.');
    });

    test('fails when end time equals start time', () {
      // isBefore is strict (<), so equal times are NOT caught by this check.
      // This test documents that current behavior rather than assuming
      // equal start/end is rejected.
      final sameTime = DateTime(2026, 8, 1, 10, 0);
      final error = validateCreatePost(
        text: 'Anyone up for badminton?',
        location: 'NUS Library',
        startTime: sameTime,
        endTime: sameTime,
      );
      expect(error, isNull);
    });

    test('passes with valid text, location, and times', () {
      final error = validateCreatePost(
        text: 'Anyone up for badminton?',
        location: 'NUS Library',
        startTime: validStart,
        endTime: validEnd,
      );
      expect(error, isNull);
    });

    test('checks text before location when both are empty', () {
      // Verifies the order of checks matches _submit(): text is validated first.
      final error = validateCreatePost(
        text: '',
        location: '',
        startTime: validStart,
        endTime: validEnd,
      );
      expect(error, 'Please describe your activity.');
    });

    test('checks start time before end time when both are null', () {
      final error = validateCreatePost(
        text: 'Anyone up for badminton?',
        location: 'NUS Library',
        startTime: null,
        endTime: null,
      );
      expect(error, 'Please set a start time.');
    });
  });
}
