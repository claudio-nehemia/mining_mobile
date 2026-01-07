import 'package:flutter/material.dart';

class ThemeConfig {
  // Dark Theme Colors (matching web backend)
  static const Color bgPrimary = Color(0xFF0F0F0F);
  static const Color bgSecondary = Color(0xFF1A1A1A);
  static const Color bgCard = Color(0xFF1A1A1A);
  
  // Gold Accent
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldHover = Color(0xFFC19B2C);
  
  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF888888);
  static const Color textTertiary = Color(0xFF999999);
  static const Color textPlaceholder = Color(0xFF777777);
  
  // Borders
  static const Color borderPrimary = Color(0xFF2A2A2A);
  static const Color borderSecondary = Color(0xFF555555);
  
  // Status Colors
  static const Color errorColor = Color(0xFFDC3545);
  static const Color successColor = Color(0xFF4ADE80);
  
  // Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      primaryColor: goldPrimary,
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: bgSecondary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borderPrimary, width: 1),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF323232).withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: goldPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textPlaceholder),
      ),
      
      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldPrimary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.w700),
        displaySmall: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 14),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 12),
      ),
    );
  }
}