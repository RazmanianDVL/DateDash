import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData get dateDashTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFFFD2D6C),     // Rich professional pink (Tinder-inspired)
    secondary: const Color(0xFF14E0C8),   // Elegant teal accent
    surface: const Color(0xFF1C1C2E),
    background: const Color(0xFF0F0F1A),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white70,
  ),
  scaffoldBackgroundColor: const Color(0xFF0F0F1A),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0F0F1A),
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
  ),
  cardTheme: CardTheme(
    color: const Color(0xFF1C1C2E),
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  textTheme: GoogleFonts.interTextTheme(
    ThemeData.dark().textTheme,
  ).copyWith(
    bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFD2D6C),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 6,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1C1C2E),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Color(0xFFFD2D6C), width: 2),
    ),
  ),
);
