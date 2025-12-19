import 'package:flutter/material.dart';

// Define the color scheme
const Color darkPurple = Color(0xFF1A1A2E);
const Color violet = Color(0xFF9370DB);
const Color skyBlue = Color(0xFF6CB4E8);
const Color darkError = Color(0xFFCF6679);
const Color lightPurple = Color(0xFF2D2D44); // Lighter purple for message input backgrounds

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: skyBlue,
  scaffoldBackgroundColor: darkPurple,

  // Font families
  fontFamily: 'Nunito',
  // Default font for body text

  colorScheme: const ColorScheme.dark(
    primary: skyBlue,
    secondary: skyBlue,
    surface: darkPurple,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    error: darkError,
  ),

  // Typography theme with custom fonts
  textTheme: const TextTheme(
    // Display styles - using Quicksand for dramatic headers
    displayLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontSize: 57,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontSize: 45,
      fontWeight: FontWeight.bold,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Quicksand',
      fontSize: 36,
      fontWeight: FontWeight.bold,
    ),

    // Headline styles - using Quicksand for app titles
    headlineLarge: TextStyle(
      fontFamily: 'Quicksand',
      fontSize: 32,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Quicksand',
      fontSize: 28,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Quicksand',
      fontSize: 24,
      fontWeight: FontWeight.w600,
    ),

    // Title styles - using Lato for section titles
    titleLarge: TextStyle(
      fontFamily: 'Lato',
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Lato',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Lato',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),

    // Body text - using Nunito for readability in messages
    bodyLarge: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 16,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 14,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 12,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.4,
    ),

    // Label styles - using Lato for buttons and UI elements
    labelLarge: TextStyle(
      fontFamily: 'Lato',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Lato',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Lato',
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: darkPurple,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'Quicksand',
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: skyBlue,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(
        fontFamily: 'Lato',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: skyBlue,
      textStyle: const TextStyle(
        fontFamily: 'Lato',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: darkPurple.withValues(alpha: 0.5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.white38, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.white38, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: skyBlue, width: 2),
    ),
    labelStyle: const TextStyle(
      fontFamily: 'Roboto',
      color: Colors.white70,
      fontWeight: FontWeight.w500,
    ),
    hintStyle: const TextStyle(
      fontFamily: 'Roboto',
      color: Colors.white54,
      fontWeight: FontWeight.normal,
    ),
  ),

  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Colors.white70,
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: skyBlue,
  ),

  tabBarTheme: const TabBarThemeData(
    labelColor: skyBlue,
    unselectedLabelColor: Colors.grey,
    indicatorColor: skyBlue,
    labelStyle: TextStyle(
      fontFamily: 'Lato',
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
    unselectedLabelStyle: TextStyle(
      fontFamily: 'Lato',
      fontSize: 14,
      fontWeight: FontWeight.normal,
    ),
  ),
);
