import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

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
    };
  }
}