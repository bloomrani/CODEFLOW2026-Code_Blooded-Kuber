import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // Add this
import 'firebase_options.dart'; // Generated automatically by 'flutterfire configure'
import 'package:kuber/providers/theme_provider.dart'; 
import 'features/dashboard/dashboard_screen.dart';

void main() async {
  // 1. Ensure Flutter engine bindings are established before native channels load
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Fire up Firebase with cross-platform configuration options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      // Keep her default entry point for now so the app runs cleanly!
      home: const DashboardScreen(analysisData: {}), 
    );
  }
}