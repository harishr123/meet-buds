import 'package:flutter/material.dart';
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
  final usernameController = TextEditingController(); //NEW
  final authService = AuthService();
  bool isLoading = false;
  String errorMessage = '';

  void signUp() async {
    if (usernameController.text.trim().isEmpty) {
      setState(() { errorMessage = 'Username is required'; });
      return;
    }
    setState(() { isLoading = true; errorMessage = ''; });
    try {
      await authService.signUp(emailController.text.trim(), passwordController.text, usernameController.text.trim());
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      setState(() { errorMessage = e.toString(); });
    }
    setState(() { isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 16),
            if (errorMessage.isNotEmpty) Text(errorMessage, style: const TextStyle(color: Colors.red)),
            isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: signUp, child: const Text('Sign Up')),
          ],
        ),
      ),
    );
  }
}