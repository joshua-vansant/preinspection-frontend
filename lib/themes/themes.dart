import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  brightness: Brightness.light,
colorScheme: ColorScheme.fromSeed(
  seedColor: Colors.blue,
  brightness: Brightness.light,
),
  scaffoldBackgroundColor: Colors.white,
  useMaterial3: true,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    elevation: 2,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    shadowColor: Colors.black12,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.black87),
    bodyLarge: TextStyle(color: Colors.black87),
    titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey[200],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  ),
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
colorScheme: ColorScheme.fromSeed(
  seedColor: Colors.blueAccent,
  brightness: Brightness.dark,
),
  scaffoldBackgroundColor: Colors.grey[900],
  useMaterial3: true,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.blueAccent,
    foregroundColor: Colors.white,
    elevation: 2,
  ),
  cardTheme: CardThemeData(
    color: Colors.grey[850],
    shadowColor: Colors.black54,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.white70),
    bodyLarge: TextStyle(color: Colors.white70),
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey[800],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  ),
);
