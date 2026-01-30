import 'package:flutter/material.dart';
import 'package:frontend/main_navigation.dart';
import 'package:frontend/screens/splash_screen/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CraveBalance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF66BB6A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF66BB6A),
          brightness: Brightness.light,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
