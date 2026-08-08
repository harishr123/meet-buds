import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;

  // Only used on web. Get this from:
  // Firebase Console -> Project settings -> Cloud Messaging tab ->
  // Web configuration -> Web Push certificates -> "Generate key pair"
  // Paste the generated key (starts with "B...") below.
  static const String _webVapidKey =
      'BHBFXAlMv6b4DEtLJu_gnWqo4Dme0owDjgBZxkrRP5p6SM_iyShRDCe47T844Kf9BmIkVC_LutLGm_GiulltSf4';

  /// Call this once the user is signed in (e.g. from HomeScreen.initState).
  /// Asks for notification permission, then saves the device's FCM token
  /// to their Firestore user doc so Cloud Functions know where to send
  /// push notifications. Also keeps the token updated if it ever refreshes.
  ///
  /// Every step logs with a [FCM] prefix. The call site in HomeScreen does not
  /// await this, so without the try/catch below any failure would surface as an
  /// unhandled async error and be effectively invisible.
  static Future<void> initialize() async {
    try {
      // Not every browser supports FCM (notably Safari before 16.4, and any
      // browser without service worker or push support). Checking first turns
      // an unsupported browser into a clean no-op instead of an exception.
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

      // Foreground messages don't show a system notification by default,
      // this listener is where you'd show an in-app banner/snackbar if wanted.
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

  /// Call this on logout so the signed-out device stops receiving
  /// notifications meant for whoever logs in next.
  static Future<void> clearToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'fcmToken': FieldValue.delete(),
    });
  }
}
