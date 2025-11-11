import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'services/auth_service.dart';
import 'services/offline_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/citizen/uber_citizen_home.dart';
import 'screens/police/uber_police_dashboard.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final AuthService _authService = AuthService();
  String? _userRole;
  bool _isLoading = true;
  double _progress = 0.0; // Track initialization progress
  String _progressMessage = 'Starting app...'; // Track what's happening

  @override
  void initState() {
    super.initState();

    // Initialize everything asynchronously to prevent blocking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServicesAndAuth();
    });
    
    // Add a timeout to ensure we don't get stuck at loading screen
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        // If still loading after 10 seconds, proceed to login screen
        setState(() {
          _isLoading = false;
          _userRole = null;
          _progress = 1.0;
          _progressMessage = 'Timeout - proceeding to login';
        });
      }
    });
  }

  Future<void> _initializeOfflineService() async {
    // This is kept for compatibility but will call the progress version
    await _initializeOfflineServiceWithProgress();
  }

  Future<void> _initializeOfflineServiceWithProgress() async {
    try {
      // Update progress: 20% for offline service initialization started
      if (mounted) {
        setState(() {
          _progress = 0.2;
          _progressMessage = 'Initializing offline service...';
        });
      }

      final offlineService = OfflineService();
      await offlineService.init();

      // Update progress: 50% for offline service initialized
      if (mounted) {
        setState(() {
          _progress = 0.5;
          _progressMessage = 'Offline service ready...';
        });
      }

      print('✅ Offline service initialized');
    } catch (e) {
      print('❌ Error initializing offline service: $e');
    }
  }

  Future<void> _checkUserRole() async {
    try {
      // Update progress: 70% for checking user role
      if (mounted) {
        setState(() {
          _progress = 0.7;
          _progressMessage = 'Checking user role...';
        });
      }

      // Use Hive.box() which will return the box if it's already open
      // This is faster than Hive.openBox() which might try to open it again
      Box prefs;
      if (Hive.isBoxOpen('preferences')) {
        prefs = Hive.box('preferences');
      } else {
        // If not opened yet, do it in background
        prefs = await Hive.openBox('preferences');
      }
      
      final role = prefs.get('user_role');

      // Update progress: 90% for role retrieved
      if (mounted) {
        setState(() {
          _progress = 0.9;
          _progressMessage = 'Loading user interface...';
        });
      }

      // Small delay to ensure progress is visible
      await Future.delayed(const Duration(milliseconds: 200));

      setState(() {
        _userRole = role;
        _isLoading = false;
        _progress = 1.0;
        _progressMessage = 'Ready!';
      });
    } catch (e) {
      print('Error checking user role: $e');
      setState(() {
        _isLoading = false;
        _userRole = null;
        _progress = 1.0;
        _progressMessage = 'Error occurred, loading default...';
      });
    }
  }

  Future<void> _initializeServicesAndAuth() async {
    // Update progress: 10% for starting initialization
    if (mounted) {
      setState(() {
        _progress = 0.1;
        _progressMessage = 'Initializing storage...';
      });
    }

    // Initialize offline service first with progress tracking
    await _initializeOfflineServiceWithProgress();

    // Update progress: 60% for services initialized
    if (mounted) {
      setState(() {
        _progress = 0.6;
        _progressMessage = 'Setting up authentication...';
      });
    }

    // Set up auth state listener for future auth changes
    _authService.currentUserStream.listen((user) {
      if (mounted) {
        if (user != null) {
          _checkUserRole();
        } else {
          setState(() {
            _isLoading = false;
            _userRole = null;
          });
        }
      }
    });

    // Check current user state immediately to update UI
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      _checkUserRole();
    } else {
      // Update progress to 80% for auth setup completed
      if (mounted) {
        setState(() {
          _progress = 0.8;
          _progressMessage = 'Authentication ready...';
        });
      }
      // If no user, we'll proceed to login (we set a small delay to show progress)
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _isLoading = false;
          _userRole = null;
          _progress = 1.0;
          _progressMessage = 'Ready to login';
        });
      }
    }
  }

  // Helper method to determine if user has police access
  bool _hasPoliceAccess() {
    return _userRole == 'police';
  }

  // Helper method to determine if user has citizen access
  bool _hasCitizenAccess() {
    return _userRole == 'citizen' || _userRole == 'police';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _progress > 0 && _progress < 1.0 ? _progress : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Crime Net',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${(_progress * 100).round()}% - $_progressMessage',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Crime Net',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: _userRole == null 
          ? LoginScreen(authService: _authService)
          : _hasPoliceAccess()
              ? const UberPoliceDashboard()
              : const UberCitizenHome(),
      routes: {
        '/login': (context) => LoginScreen(authService: _authService),
        '/citizen': (context) => _hasCitizenAccess() 
            ? const UberCitizenHome() 
            : LoginScreen(authService: _authService),
        '/police': (context) => _hasPoliceAccess()
            ? const UberPoliceDashboard()
            : LoginScreen(authService: _authService),
      },
    );
  }
}
