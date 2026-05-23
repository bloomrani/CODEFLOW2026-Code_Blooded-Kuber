import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// 👇 CRITICAL: Make sure this path exactly matches where the file you just opened is!
// If it's inside a 'theme' folder, it should be: import 'theme/theme_provider.dart';
import 'providers/theme_provider.dart'; 

import 'features/splash_screen.dart'; // Adjust this path if needed

void main() async {
  // 1. Lock the framework
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Turn on Firebase
  await Firebase.initializeApp(); 

  // 3. Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🌟 FIXED: We are officially wrapping the entire app in Rani's ThemeProvider!
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(), 
      child: MaterialApp(
        title: 'Kuber AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        
        // This launches your splash screen, which goes to login, which goes to upload!
        home: const SplashScreen(), 
      ),
    );
  }
}