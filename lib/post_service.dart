import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'post_model.dart';

class PostService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  Stream<List<PostModel>> getFeed() {
    return _db
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PostModel.fromFirestore).toList());
  }

  Future<String> _uploadImage(File image, String postId, int index) async {
    final ref = _storage.ref('posts/$postId/image_$index.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> createPost({
    required String text,
    required List<File> images,
    String? location,
  }) async {
    final user = _auth.currentUser!;
    final postRef = _db.collection('posts').doc();

    // Upload images
    final imageUrls = <String>[];
    for (int i = 0; i < images.length; i++) {
      final url = await _uploadImage(images[i], postRef.id, i);
      imageUrls.add(url);
    }

    // Get username from Firestore users collection
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final username = userDoc.data()?['username'] ?? user.email ?? 'Anonymous';
    final avatar = userDoc.data()?['avatarUrl'];

    await postRef.set(PostModel(
      id: postRef.id,
      userId: user.uid,
      username: username,
      userAvatar: avatar,
      text: text,
      imageUrls: imageUrls,
      location: location,
      timestamp: DateTime.now(),
      likes: [],
    ).toMap());
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

  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }
}
