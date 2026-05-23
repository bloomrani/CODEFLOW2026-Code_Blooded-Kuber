import 'package:flutter/material.dart';

class AppColors {
  // --- PREMIUM DARK THEME ---
  static const Color darkBg = Color(0xFF0F172A); // Deep Slate
  static const Color darkCard = Color(0xFF1E293B); // Raised Slate Layer
  static const Color darkAccent = Color(0xFF38BDF8); // Neon Cyan
  static const Color darkDoodle = Color(0xFF334155); // Faint background elements

  // --- PREMIUM LIGHT THEME ---
  static const Color lightBg = Color(0xFFF4F6F8); // Very Soft Pearl
  static const Color lightCard = Colors.white; // Crisp White
  static const Color lightAccent = Color(0xFF6366F1); // Deep Indigo
  static const Color lightDoodle = Color(0xFFE2E8F0); // Faint background elements

  // --- SHARED TEXT COLORS ---
  static const Color textWhite = Color(0xFFF8FAFC);
  static const Color textBlack = Color(0xFF0F172A);
  static const Color subTextDark = Color(0xFF94A3B8);
  static const Color subTextLight = Color(0xFF64748B);
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