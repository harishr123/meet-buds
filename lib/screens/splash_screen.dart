import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'verify_email_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNextScreen();
  }

  Future<void> _decideNextScreen() async {
    // Minimum display time so the splash doesn't flash on fast connections.
    final delay = Future.delayed(const Duration(milliseconds: 1400));

    var user = FirebaseAuth.instance.currentUser;

    // If the user opted out of staying signed in, end the session now.
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool('remember_me') ?? true;
      if (!remember) {
        await FirebaseAuth.instance.signOut();
        user = null;
      }
    }

    try {
      await user?.reload();
    } catch (_) {
      // Offline or transient failure. Fall through with cached auth state.
    }

    await delay;
    if (!mounted) return;

    final current = FirebaseAuth.instance.currentUser;
    Widget next;
    if (current == null) {
      next = const LoginScreen();
    } else if (!current.emailVerified) {
      next = const VerifyEmailScreen();
    } else {
      next = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Meeting Buddies',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: Color(0xFF3C3489),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Find your next activity buddy at NUS',
              style: TextStyle(fontSize: 13.5, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
