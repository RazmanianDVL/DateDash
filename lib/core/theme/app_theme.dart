import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData get dateDashTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFFFD2D6C), // Professional Tinder-inspired vibrant pink-red
    secondary: const Color(0xFF14E0C8), // Elegant toned teal accent
    surface: const Color(0xFF1C1C2E),
    background: const Color(0xFF0F0F1A),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white70,
  ),
  scaffoldBackgroundColor: const Color(0xFF0F0F1A),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0F0F1A),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardTheme(
    color: const Color(0xFF1C1C2E),
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
  textTheme: GoogleFonts.interTextTheme(
    ThemeData.dark().textTheme.copyWith(
      displayLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
      titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      bodyLarge: const TextStyle(fontSize: 16, color: Colors.white70),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFD2D6C),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(vertical: 18),
      elevation: 6,
      shadowColor: const Color(0xFFFD2D6C).withOpacity(0.4),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1C1C2E),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFF1C1C2E),
    selectedColor: const Color(0xFFFD2D6C),
    labelStyle: const TextStyle(color: Colors.white),
  ),
);
