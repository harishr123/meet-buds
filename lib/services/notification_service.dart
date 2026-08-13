import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;

  static const String _webVapidKey =
      'BHBFXAlMv6b4DEtLJu_gnWqo4Dme0owDjgBZxkrRP5p6SM_iyShRDCe47T844Kf9BmIkVC_LutLGm_GiulltSf4';

  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        final supported = await FirebaseMessaging.instance.isSupported();
        if (!supported) return;
      }

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? _webVapidKey : null,
      );

      await _saveToken(token);

      _messaging.onTokenRefresh.listen(_saveToken);

      FirebaseMessaging.onMessage.listen((message) {});
    } catch (e, st) {}
  }

  static Future<void> _saveToken(String? token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || token == null) return;
    await _db.collection('users').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  static Future<void> clearToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'fcmToken': FieldValue.delete(),
    });
  }
}
