import 'package:flutter/material.dart';

// Define the color scheme
const Color darkPurple = Color(0xFF1A1A2E);
const Color violet = Color(0xFF9370DB);
const Color fluorescentTeal = Color(0xFF00F5D4);
const Color darkError = Color(0xFFCF6679);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: violet,
  scaffoldBackgroundColor: darkPurple,
  colorScheme: const ColorScheme.dark(
    primary: violet,
    secondary: fluorescentTeal,
    background: darkPurple,
    surface: darkPurple,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onBackground: Colors.white,
    onSurface: Colors.white,
    error: darkError,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: darkPurple, 
    elevation: 0,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: fluorescentTeal, // background (button) color
      foregroundColor: Colors.white, // foreground (text) color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: fluorescentTeal, // text color
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: darkPurple.withOpacity(0.5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: fluorescentTeal),
    ),
    labelStyle: const TextStyle(color: Colors.white70),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: fluorescentTeal,
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: fluorescentTeal,
    unselectedLabelColor: Colors.grey,
    indicatorColor: fluorescentTeal,
  ),
);
