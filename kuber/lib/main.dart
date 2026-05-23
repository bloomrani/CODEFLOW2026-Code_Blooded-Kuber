import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
// 👇 Import your new splash screen 👇
import 'features/splash_screen.dart'; 

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const KuberApp(),
    ),
  );
}

class KuberApp extends StatelessWidget {
  const KuberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kuber AI',
      debugShowCheckedModeBanner: false,
      
      // 👇 THIS creates the smooth fade when toggling Dark/Light mode! 👇
      themeAnimationDuration: const Duration(milliseconds: 600),
      themeAnimationCurve: Curves.easeInOut,
      
      // Starts the app on your new Splash Screen
      home: const SplashScreen(), 
    );
  }
}