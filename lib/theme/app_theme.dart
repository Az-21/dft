import 'package:flutter/material.dart';

/// Application seed color used when platform dynamic color is unavailable
const appSeedColor = Color(0xFF386A20);

/// Identifier of the bundled monospace family declared in `pubspec.yaml`
const monoFontFamily = 'JetBrainsMono';

/// Central place for [ThemeData] construction and shared text styles
///
/// Relies on Flutter defaults for Material 3 and predictive back
/// Dynamic color harmonization happens in `MyApp`
abstract final class AppTheme {
  /// Single builder shared by the light and dark themes
  static ThemeData build(ColorScheme scheme) {
    return ThemeData(colorScheme: scheme);
  }

  static ColorScheme fallbackLightScheme() {
    return ColorScheme.fromSeed(seedColor: appSeedColor);
  }

  static ColorScheme fallbackDarkScheme() {
    return ColorScheme.fromSeed(
      seedColor: appSeedColor,
      brightness: Brightness.dark,
    );
  }

  /// Monospace style for numeric readouts; call sites add sizes as needed
  static const TextStyle mono = TextStyle(fontFamily: monoFontFamily);
}
