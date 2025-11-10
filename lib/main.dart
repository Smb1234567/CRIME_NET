import 'package:flutter/material.dart';
import 'app.dart';

void main() {
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
      ),
      home: const App(),
      debugShowCheckedModeBanner: false,
    );
  }
}
