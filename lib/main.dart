import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  print('🚀 Starting Crime Net App (Mock Mode)...');
  runApp(const CrimeNetApp());
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
