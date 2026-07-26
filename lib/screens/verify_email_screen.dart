import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  bool _resending = false;
  String? _resendMessage;

  @override
  void initState() {
    super.initState();
    // Poll every 3 seconds to check if verified
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        _timer?.cancel();
        if (mounted) {
          Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    setState(() { _resending = true; _resendMessage = null; });
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      setState(() => _resendMessage = 'Verification email resent!');
    } catch (e) {
      setState(() => _resendMessage = 'Could not resend. Try again shortly.');
    }
    setState(() => _resending = false);
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text('Check your email',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('We sent a verification link to',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Text(email,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF0C447C), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Click the link in the email to verify your account. This page will automatically redirect once verified.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (_resendMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_resendMessage!,
                      style: TextStyle(
                          fontSize: 13,
                          color: _resendMessage!.contains('resent')
                              ? const Color(0xFF085041)
                              : const Color(0xFFA32D2D))),
                ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: _resending
                    ? const Center(child: CircularProgressIndicator())
                    : OutlinedButton(
                        onPressed: _resendEmail,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Resend verification email'),
                      ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _signOut,
                  child: Text('Sign out',
                      style: TextStyle(color: Colors.grey.shade500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}