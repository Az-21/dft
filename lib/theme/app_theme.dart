import 'package:flutter/material.dart';

/// Application seed color used when platform dynamic color is unavailable
const appSeedColor = Color(0xFF386A20);

/// Centralizes light/dark [ThemeData] construction.
///
/// Behavior is intentionally identical to the previous inline themes in
/// `MyApp`; this file only gives them a named home under `lib/theme/`
/// as part of the feature-first layout.
abstract final class AppTheme {
  static ThemeData light(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData dark(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
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
}
