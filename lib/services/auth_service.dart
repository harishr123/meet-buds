import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// auth_service to handle all firebase authentication 
// Keeps auth code in seperate place
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

//login user with email and password
  Future<UserCredential?> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed';
    }
  }
//new user sign up with email and password
  Future<UserCredential?> signUp(String email, String password, String username) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Save user information to Firestore
      await _db.collection('users').doc(cred.user?.uid).set({
        'email': email,
        'username': username,
        'avatarUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return cred;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Sign up failed';
    }
  }
//log out user
  Future<void> signOut() async {
    await _auth.signOut();
  }
}