import 'dart:async';
import '../models/user_model.dart';

class AuthService {
  AppUser? _currentUser;
  final StreamController<AppUser?> _userController =
      StreamController<AppUser?>.broadcast();

  AuthService() {
    // Start with no user
    _userController.add(null);
  }

  // Mock authentication - works with any email/password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    _currentUser = AppUser(
      uid: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      role: 'citizen',
      displayName: email.split('@').first,
      createdAt: DateTime.now(),
    );

    _userController.add(_currentUser);
    print('✅ Signed in as: $email');
  }

  // Mock anonymous sign in
  Future<void> signInAnonymously() async {
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = AppUser(
      uid: 'anonymous-${DateTime.now().millisecondsSinceEpoch}',
      email: 'guest@example.com',
      role: 'citizen',
      displayName: 'Guest User',
      createdAt: DateTime.now(),
    );

    _userController.add(_currentUser);
    print('✅ Signed in anonymously');
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _userController.add(null);
    print('✅ Signed out');
  }

  AppUser? get currentUser => _currentUser;
  Stream<AppUser?> get currentUserStream => _userController.stream;
}
