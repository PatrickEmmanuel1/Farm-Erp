import 'package:flutter/material.dart';

class FarmTheme {
  static const Color primaryGreen = Color(0xFF2E6F3B);
  static const Color accentGreen = Color(0xFF4D7F52);
  static const Color softBackground = Color(0xFFF1F1EA);
  static const Color errorRed = Color(0xFFB3261E);

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: softBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      secondary: accentGreen,
      surface: Colors.white,
      error: errorRed,
    ),
    textTheme: Typography.blackMountainView.copyWith(
      headlineMedium: const TextStyle(
        color: Color(0xFF2E2E2E),
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      bodyLarge: const TextStyle(
        color: Color(0xFF444444),
        fontWeight: FontWeight.w400,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryGreen,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF3A7A3A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF3A7A3A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2E6F3B), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF4A4A4A)),
      prefixIconColor: const Color(0xFF3A7A3A),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryGreen,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
