// * Theme data

import 'package:flutter/material.dart';

class Themes {
  final darkTheme = ThemeData.dark().copyWith(
    useMaterial3: true,
    brightness: Brightness.dark,
  );

  final lightTheme = ThemeData.light().copyWith(
    useMaterial3: true,
    brightness: Brightness.light,
  );
}
