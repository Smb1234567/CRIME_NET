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
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Choose Your Role',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How would you like to use Crime Net?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView(
                  children: [
                    _buildRoleCard(
                      context,
                      title: 'Community Member',
                      description: 'Report incidents, help your community, and stay informed about local safety',
                      features: [
                        'Anonymous Reporting',
                        'Community Alerts', 
                        'Safety Maps',
                      ],
                      icon: Icons.security,
                      color: Colors.blue,
                      onTap: () => _selectRole('citizen'),
                    ),
                    const SizedBox(height: 24),
                    _buildRoleCard(
                      context,
                      title: 'Police Officer',
                      description: 'Access real-time reports, monitor community safety, and coordinate responses',
                      features: [
                        'Real-time Dashboard',
                        'Mesh Network Access',
                        'Advanced Analytics',
                      ],
                      icon: Icons.badge,
                      color: Colors.green,
                      onTap: () => _selectRole('police'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String description,
    required List<String> features,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.grey[800],
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: color, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      feature,
                      style: TextStyle(
                        color: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}