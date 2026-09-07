import 'package:dft/routing/app_router.dart';
import 'package:dft/theme/app_theme.dart';
import 'package:dft/theme/theme_controller.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

/// Root application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds MaterialApp only when the manual theme override changes
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            // Each brightness falls back independently when dynamic color
            // is unavailable
            final lightScheme =
                lightDynamic?.harmonized() ?? AppTheme.fallbackLightScheme();
            final darkScheme =
                darkDynamic?.harmonized() ?? AppTheme.fallbackDarkScheme();

            return MaterialApp.router(
              title: 'DFT Calculator',
              theme: AppTheme.build(lightScheme),
              darkTheme: AppTheme.build(darkScheme),
              themeMode: mode,
              routerConfig: router,
            );
          },
        );
      },
    );
  }
}
