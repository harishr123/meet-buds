import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityStatus { upcoming, ongoing, completed }

class PostModel {
  final String id;
  final String userId;
  final String username;
  final String? userAvatar;
  final String text;
  final List<String> imageUrls;
  final String? location;
  final DateTime timestamp;
  final List<String> likes;
  final List<String> joinedBy;
  final String activityType;
  final int maxParticipants;
  final DateTime? startTime;
  final DateTime? endTime;

  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.text,
    required this.imageUrls,
    this.location,
    required this.timestamp,
    required this.likes,
    required this.joinedBy,
    required this.activityType,
    required this.maxParticipants,
    this.startTime,
    this.endTime,
  });

  ActivityStatus get status {
    final now = DateTime.now();
    if (startTime == null || endTime == null) return ActivityStatus.upcoming;
    if (now.isBefore(startTime!)) return ActivityStatus.upcoming;
    if (now.isAfter(endTime!)) return ActivityStatus.completed;
    return ActivityStatus.ongoing;
  }

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Anonymous',
      userAvatar: data['userAvatar'],
      text: data['text'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      location: data['location'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likes: List<String>.from(data['likes'] ?? []),
      joinedBy: List<String>.from(data['joinedBy'] ?? []),
      activityType: data['activityType'] ?? 'general',
      maxParticipants: data['maxParticipants'] ?? 0,
      startTime: data['startTime'] != null
          ? (data['startTime'] as Timestamp).toDate()
          : null,
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'text': text,
      'imageUrls': imageUrls,
      'location': location,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'joinedBy': joinedBy,
      'activityType': activityType,
      'maxParticipants': maxParticipants,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
    };
  }
}