import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
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
        debugPrint('[FCM] messaging supported on this browser: $supported');
        if (!supported) return;
      }

      debugPrint('[FCM] requesting permission...');
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM] permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] permission denied — stopping here');
        return;
      }

      debugPrint('[FCM] getting token...');
      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? _webVapidKey : null,
      );
      debugPrint(
        '[FCM] token: ${token == null ? "NULL" : "${token.substring(0, 12)}..."}',
      );

      await _saveToken(token);
      debugPrint('[FCM] token saved to Firestore');

      _messaging.onTokenRefresh.listen(_saveToken);


      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('[FCM] foreground message: ${message.notification?.title}');
      });
    } catch (e, st) {
      debugPrint('[FCM] initialize failed: $e');
      debugPrint('$st');
    }
  }

  static Future<void> _saveToken(String? token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || token == null) return;
    await _db.collection('users').doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }


  static Future<void> clearToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'fcmToken': FieldValue.delete(),
    });
  }
}
