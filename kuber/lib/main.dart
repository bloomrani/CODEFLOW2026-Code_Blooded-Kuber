import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// THIS IS THE LINE THAT FIXED THE ERROR! 
// It tells main.dart to look inside the features/upload/ folder.
import 'features/upload/upload_screen.dart'; 

void main() {
  runApp(const KuberApp());
}

class KuberApp extends StatelessWidget {
  const KuberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kuber AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C5DD3), 
          secondary: Color(0xFF00F2FE),
          surface: Color(0xFF18181C),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const UploadScreen(),
    );
  }
}