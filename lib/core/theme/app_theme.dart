import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData get dateDashTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFFFF2D95), // hot pink
    secondary: const Color(0xFF00F0FF), // neon cyan
    surface: const Color(0xFF0F0F1A),
    background: const Color(0xFF0A0A14),
    onPrimary: Colors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFF0A0A14),
  textTheme: GoogleFonts.interTextTheme(
    ThemeData.dark().textTheme.copyWith(
      displayLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
      titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFF2D95),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(vertical: 18),
      elevation: 8,
      shadowColor: const Color(0xFFFF2D95).withOpacity(0.5),
    ),
  ),
);
