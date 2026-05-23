import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Replace 'kuber_app' with the name defined in your pubspec.yaml
import 'package:kuber/providers/theme_provider.dart'; 
import 'features/dashboard/dashboard_screen.dart';

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      // Ensure you pass your analysisData here or handle it via a state manager
      home: const DashboardScreen(analysisData: {}), 
    );
  }
}