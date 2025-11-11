import 'package:flutter/material.dart';
import 'package:crime_net/services/auth_service.dart';
import 'package:crime_net/screens/citizen/citizen_home.dart';
import 'package:crime_net/screens/police/police_dashboard.dart';

class RoleSelectionScreen extends StatefulWidget {
  final AuthService authService;
  const RoleSelectionScreen({super.key, required this.authService});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  void _setUserRole(String role) {
    print('🎯 User selected role: $role');

    if (role == 'citizen') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CitizenHome()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PoliceDashboard()),
      );
    }
  }

  void _logout() {
    widget.authService.signOut();
    // Navigation will be handled by App widget listening to auth state
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Role'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'How will you use Crime Net?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Citizen Card
            Card(
              elevation: 4,
              color: _selectedRole == 'citizen' ? Colors.blue[50] : null,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedRole = 'citizen';
                  });
                  _setUserRole('citizen');
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      const Icon(Icons.people, size: 40, color: Colors.blue),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Citizen',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Report safety concerns and suspicious activities in your area',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedRole == 'citizen')
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Police Card
            Card(
              elevation: 4,
              color: _selectedRole == 'police' ? Colors.green[50] : null,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedRole = 'police';
                  });
                  _setUserRole('police');
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      const Icon(Icons.security, size: 40, color: Colors.green),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Police Officer',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Monitor reports, track hotspots, and coordinate responses',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedRole == 'police')
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Quick switch info
            const Text(
              '💡 Tip: Use the logout button to switch roles anytime',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
