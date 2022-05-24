// * Theme data

import 'package:flutter/material.dart';

class Themes {
  final lightTheme = ThemeData.light().copyWith(
    useMaterial3: true,
    primaryColor: Colors.green,
    appBarTheme: const AppBarTheme(
      color: Colors.green,
    ),
    brightness: Brightness.light,
  );

  final darkTheme = ThemeData.dark().copyWith(
    useMaterial3: true,
    primaryColor: Colors.green,
    appBarTheme: const AppBarTheme(
      color: Colors.green,
    ),
    brightness: Brightness.dark,
  );
}
