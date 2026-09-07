import 'package:dft/routing/app_router.dart';
import 'package:dft/theme/app_theme.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:easy_dynamic_theme/easy_dynamic_theme.dart';
import 'package:flutter/material.dart';

/// Root application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final ColorScheme lightColorScheme;
        final ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // On Android S+ devices, use the provided dynamic color scheme
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          // Otherwise, use fallback schemes
          lightColorScheme = AppTheme.fallbackLightScheme();
          darkColorScheme = AppTheme.fallbackDarkScheme();
        }

        return MaterialApp.router(
          title: 'DFT Calculator',
          theme: AppTheme.light(lightColorScheme),
          darkTheme: AppTheme.dark(darkColorScheme),
          themeMode: EasyDynamicTheme.of(context).themeMode,
          routerConfig: router,
        );
      },
    );
  }
}
