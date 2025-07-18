import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔐 Sign in with email & password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('General Error: $e');
      rethrow;
    }
  }

  // ✅ Register with email & password
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('General Error: $e');
      rethrow;
    }
  }

  // 🔐 Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
