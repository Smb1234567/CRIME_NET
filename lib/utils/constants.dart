import 'package:flutter/material.dart'; // ADD THIS IMPORT

class AppConstants {
  // Report types for quick templates
  static const List<Map<String, String>> reportTypes = [
    {'value': 'suspicious_vehicle', 'label': '🚗 Suspicious Vehicle'},
    {'value': 'intimidation', 'label': '⚠️ Intimidation/Harassment'},
    {'value': 'theft', 'label': '💰 Theft/Burglary'},
    {'value': 'vandalism', 'label': '🎨 Vandalism'},
    {'value': 'disturbance', 'label': '🔊 Noise Disturbance'},
    {'value': 'suspicious_person', 'label': '👤 Suspicious Person'},
    {'value': 'drug_activity', 'label': '💊 Drug Activity'},
    {'value': 'other', 'label': '📝 Other'},
  ];

  // Priority levels
  static const Map<int, String> priorityLabels = {
    1: 'Low',
    2: 'Medium',
    3: 'High',
    4: 'Urgent',
    5: 'Emergency',
  };

  static const Map<int, Color> priorityColors = {
    1: Colors.green,
    2: Colors.blue,
    3: Colors.orange,
    4: Colors.red,
    5: Colors.purple,
  };

  // Reputation levels
  static const Map<String, int> reputationThresholds = {
    'Beginner': 0,
    'Contributor': 100,
    'Trusted Reporter': 500,
    'Community Leader': 1000,
    'Safety Expert': 2000,
  };
}
