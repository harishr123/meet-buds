import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  final bioController = TextEditingController();
  final authService = AuthService();
  bool isLoading = false;
  String errorMessage = '';

  String _friendlyError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  void signUp() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final bio = bioController.text.trim();

    if (username.isEmpty) {
      setState(() => errorMessage = 'Please enter a username.');
      return;
    }
    if (email.isEmpty) {
      setState(() => errorMessage = 'Please enter your email.');
      return;
    }
    if (password.isEmpty) {
      setState(() => errorMessage = 'Please enter a password.');
      return;
    }

    setState(() { isLoading = true; errorMessage = ''; });
    try {
      final cred = await authService.signUp(email, password, username);
      if (bio.isNotEmpty && cred?.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred!.user!.uid)
            .update({'bio': bio});
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      setState(() { errorMessage = _friendlyError(e); });
    }
    if (mounted) setState(() { isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text('Create account',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Find your next activity buddy at NUS',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
              const SizedBox(height: 40),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bioController,
                maxLines: 3,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'Bio (optional)',
                  hintText: 'Tell others a bit about yourself...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.edit_outlined),
                  alignLabelWithHint: true,
                  counterStyle: TextStyle(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 8),
              if (errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEBEB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: Color(0xFFA32D2D)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(errorMessage,
                            style: const TextStyle(color: Color(0xFFA32D2D), fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: signUp,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Create account',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Already have an account? Sign in',
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}