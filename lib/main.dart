import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crime_net/services/offline_service.dart';
import 'app.dart';

void main() async {
  print('🚀 Starting Crime Net App (Offline Capable)...');
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize offline service
  final offlineService = OfflineService();
  await offlineService.init();
  
  // Start background sync process
  _startBackgroundTasks();
  
  runApp(const CrimeNetApp());
}

void _startBackgroundTasks() {
  // This would run in a separate isolate in a real app
  // For now, we'll simulate background tasks
  print('🔄 Starting background sync tasks...');
}

class CrimeNetApp extends StatelessWidget {
  const CrimeNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crime Net',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const App(),
      debugShowCheckedModeBanner: false,
    );
  }
}
