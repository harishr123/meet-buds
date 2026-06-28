import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_model.dart';

class PostService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<List<PostModel>> getFeed() {
    return _db
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PostModel.fromFirestore).toList());
  }

  Future<void> createPost({
    required String text,
    required List<String> images,
    String? location,
    String activityType = 'general',
    int maxParticipants = 0,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final user = _auth.currentUser!;
    final postRef = _db.collection('posts').doc();
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final username = userDoc.data()?['username'] ?? user.email ?? 'Anonymous';
    final avatar = userDoc.data()?['avatarUrl'];
    await postRef.set(PostModel(
      id: postRef.id,
      userId: user.uid,
      username: username,
      userAvatar: avatar,
      text: text,
      imageUrls: [],
      location: location,
      timestamp: DateTime.now(),
      likes: [],
      joinedBy: [],
      activityType: activityType,
      maxParticipants: maxParticipants,
      startTime: startTime,
      endTime: endTime,
    ).toMap());
  }

  Future<void> updatePost({
    required String postId,
    required String newText,
    String? newLocation,
    DateTime? newStartTime,
    DateTime? newEndTime,
  }) async {
    await _db.collection('posts').doc(postId).update({
      'text': newText,
      'location': newLocation,
      'startTime': newStartTime != null ? Timestamp.fromDate(newStartTime) : null,
      'endTime': newEndTime != null ? Timestamp.fromDate(newEndTime) : null,
    });
  }

  Future<void> toggleLike(String postId) async {
    final uid = _auth.currentUser!.uid;
    final ref = _db.collection('posts').doc(postId);
    final doc = await ref.get();
    final likes = List<String>.from(doc['likes'] ?? []);
    if (likes.contains(uid)) {
      likes.remove(uid);
    } else {
      likes.add(uid);
    }
    await ref.update({'likes': likes});
  }

  Future<void> toggleJoin(String postId) async {
    final uid = _auth.currentUser!.uid;
    final ref = _db.collection('posts').doc(postId);
    final doc = await ref.get();
    final data = doc.data() as Map<String, dynamic>?;
    final joinedBy = List<String>.from(data?['joinedBy'] ?? []);
    if (joinedBy.contains(uid)) {
      joinedBy.remove(uid);
    } else {
      joinedBy.add(uid);
    }
    await ref.update({'joinedBy': joinedBy});
  }

  Future<List<String>> getJoinedUsernames(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final results = await Future.wait(
      userIds.map((uid) => _db.collection('users').doc(uid).get()),
    );
    return results.map<String>((doc) {
      return doc.data()?['username'] ?? 'Anonymous';
    }).toList();
  }

  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<void> updateBio(String bio) async {
    final uid = _auth.currentUser!.uid;
    await _db.collection('users').doc(uid).update({'bio': bio});
  }

  Stream<List<PostModel>> getPostsByUser(String userId) {
    return _db
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PostModel.fromFirestore).toList());
  }

  Stream<List<PostModel>> getJoinedActivities(String userId) {
    return _db
        .collection('posts')
        .where('joinedBy', arrayContains: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PostModel.fromFirestore).toList());
  }
}