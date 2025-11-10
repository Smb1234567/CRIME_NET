import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _ensureUserDocument(result.user!);
    } catch (e) {
      rethrow;
    }
  }

  // Sign in anonymously
  Future<void> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      await _ensureUserDocument(result.user!);
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<void> registerWithEmailAndPassword(
      String email, String password, String displayName, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      AppUser user = AppUser(
        uid: result.user!.uid,
        email: email,
        role: role,
        displayName: displayName,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(user.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Ensure user document exists
  Future<void> _ensureUserDocument(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      AppUser newUser = AppUser(
        uid: user.uid,
        email: user.email ?? 'anonymous@example.com',
        role: 'citizen',
        displayName: user.displayName ?? 'Anonymous User',
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
}
