import 'package:flutter/material.dart';

class PicpacTheme {
  const PicpacTheme._();

  static ThemeData light() {
    const seed = Color(0xFF48B3AF);
    final scheme = ColorScheme.fromSeed(seedColor: seed);
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SF Pro',
      colorScheme: scheme.copyWith(
        primary: seed,
        secondary: const Color(0xFFA7E399),
        surface: const Color(0xFFFCF8F5),
        error: const Color(0xFFCE472A),
      ),
      scaffoldBackgroundColor: const Color(0xFFFCF8F5),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFFFCF8F5),
        foregroundColor: Color(0xFF173B3A),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
