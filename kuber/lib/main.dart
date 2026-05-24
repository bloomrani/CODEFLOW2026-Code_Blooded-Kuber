import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 🌟 REQUIRED: This contains all your web and mobile API keys
import 'firebase_options.dart'; 

// 👇 CRITICAL: Make sure this path exactly matches where the file you just opened is!
import 'providers/theme_provider.dart'; 

import 'features/splash_screen.dart'; // Adjust this path if needed

void main() async {
  // 1. Lock the framework
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Turn on Firebase (Platform Compliant!)
  // 🚀 THE FIX: This safely routes your Web keys to Chrome, and your Mobile keys to your Alienware emulator.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 
  
  await FirebaseAuth.instance.signOut();

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