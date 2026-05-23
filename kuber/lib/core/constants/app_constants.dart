import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme
  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  
  // Light Theme
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color lightCard = Colors.white;

  // Shared
  static const Color accentBlue = Colors.blueAccent;
  static const Color textWhite = Colors.white;
  static const Color textBlack = Colors.black87;
  static const Color subTextDark = Color(0xFFBDBDBD); // Grey.shade400
  static const Color subTextLight = Color(0xFF757575); // Grey.shade600
}

class ApiConstants {
  static const String baseUrl = 'https://fantastic-exhaust-neutron.ngrok-free.dev';
  static const String analyzeEndpoint = '/analyze';
}

class AppStrings {
  static const String appName = 'Kuber AI Analysis';
  static const String loadingMessage = 'Kuber is crunching your numbers...';
}