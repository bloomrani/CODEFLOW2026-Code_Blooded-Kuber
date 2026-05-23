import 'package:flutter/material.dart';

class AppColors {
  // Deep Bluish-Teal Theme (Eye-friendly)
  static const Color darkBg = Color(0xFF092624);     // Deep, relaxing bluish-teal background
  static const Color darkCard = Color(0xFF13403A);   // Elevated teal card color
  
  // Light Theme (Soft minty-white to keep the teal vibe)
  static const Color lightBg = Color(0xFFF0F5F4);
  static const Color lightCard = Colors.white;

  // Golden Accents
  static const Color goldAccent = Color(0xFFD4AF37); // Premium Champagne Gold for text
  static const Color goldBright = Color(0xFFFFD700); // Bright Gold for icons

  // Shared Text Colors
  static const Color textWhite = Colors.white;
  static const Color textBlack = Color(0xFF121212);
  static const Color subTextDark = Color(0xFFA4C2BC); // Soft teal-tinted grey
  static const Color subTextLight = Color(0xFF63827C);
}

class ApiConstants {
  // Remember to update this if your ngrok restarts!
  static const String baseUrl = 'https://fantastic-exhaust-neutron.ngrok-free.dev';
  static const String analyzeEndpoint = '/analyze';
}

class AppStrings {
  static const String appName = 'Kuber AI Analysis';
  static const String loadingMessage = 'Kuber is crunching your numbers...';
}