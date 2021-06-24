// * Theme data

import 'package:flutter/material.dart';

class Themes {
  final lightTheme = ThemeData.light().copyWith(
    primaryColor: Colors.green,
    appBarTheme: const AppBarTheme(
      color: Colors.green,
    ),
    brightness: Brightness.light,
  );

  final darkTheme = ThemeData.dark().copyWith(
    primaryColor: Colors.green,
    appBarTheme: const AppBarTheme(
      color: Colors.green,
    ),
    brightness: Brightness.dark,
  );
}
