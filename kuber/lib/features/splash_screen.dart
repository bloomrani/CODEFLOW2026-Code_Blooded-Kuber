import 'package:flutter/material.dart';
import 'dart:async';
import 'upload/upload_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // Controls the smooth fade-in speed of the logo (1.5 seconds)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // Waits 3.5 seconds total, then routes to the Upload Screen
    Timer(const Duration(milliseconds: 3500), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UploadScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 👇 This hex code perfectly matches the deep background of your Kuber logo! 👇
      backgroundColor: const Color(0xFF0F363A), 
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset(
            'assets/logo.png', // Ensure this matches your asset filename!
            width: 250, 
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}