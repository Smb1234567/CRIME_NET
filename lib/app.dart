import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/role_selection_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // Listen for auth state changes
    _authService.currentUserStream.listen((user) {
      if (mounted) {
        setState(() {
          _isLoggedIn = user != null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn
        ? RoleSelectionScreen(authService: _authService)
        : LoginScreen(authService: _authService);
  }
}
