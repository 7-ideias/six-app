import 'package:flutter/material.dart';

// Tema claro
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.blue,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    color: Colors.blue,
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
  ),
  cardColor: Colors.white,
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.black),
  ),
);

// Tema escuro
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.grey[900],
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: AppBarTheme(
    color: Colors.grey[900],
    titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
  ),
  cardColor: Colors.grey[800],
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.white),
  ),
);
