import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:crime_net/services/auth_service.dart';
import '../citizen/uber_citizen_home.dart';
import '../police/uber_police_dashboard.dart';

class RoleSelectionScreen extends StatefulWidget {
  final AuthService authService;
  
  const RoleSelectionScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  Future<void> _selectRole(String role) async {
    // Store role preference
    final prefs = await Hive.openBox('preferences');
    await prefs.put('user_role', role);

    // Navigate to appropriate screen
    if (role == 'police') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UberPoliceDashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UberCitizenHome()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              
              // Header
              const Column(
                children: [
                  Text(
                    'Choose Your Role',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'How would you like to use Crime Net?',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              
              const Spacer(flex: 2),
              
              // Role Cards
              Column(
                children: [
                  // Citizen Card
                  GestureDetector(
                    onTap: () => _selectRole('citizen'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.people,
                            color: Colors.blue,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Community Member',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Report incidents, help your community, and stay informed about local safety',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 16),
                              SizedBox(width: 8),
                              Text('Anonymous Reporting', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 16),
                              SizedBox(width: 8),
                              Text('Community Alerts', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 16),
                              SizedBox(width: 8),
                              Text('Safety Maps', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Police Card
                  GestureDetector(
                    onTap: () => _selectRole('police'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.security,
                            color: Colors.red,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Police Officer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Access real-time reports, monitor community safety, and coordinate responses',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 16),
                              SizedBox(width: 8),
                              Text('Real-time Dashboard', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 16),
                              SizedBox(width: 8),
                              Text('Mesh Network Access', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 16),
                              SizedBox(width: 8),
                              Text('Analytics & Reports', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const Spacer(flex: 1),
              
              // Info Text
              const Text(
                'Your role determines the features you can access. You can change this later in settings.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}