import 'package:dft/routes.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:easy_dynamic_theme/easy_dynamic_theme.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter black magic. Wasted three hours on this.
  runApp(
    EasyDynamicThemeWidget(
      child: const MyApp(),
    ),
  );
}

const _fallbackGreen = Color(0xFF386A20);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // On Android S+ devices, use the provided dynamic color scheme.
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          // Otherwise, use fallback schemes.
          lightColorScheme = ColorScheme.fromSeed(
            seedColor: _fallbackGreen,
          );
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: _fallbackGreen,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp.router(
          title: 'DFT Calculator',
          theme: ThemeData(
            colorScheme: lightColorScheme,
            useMaterial3: true,
            // pageTransitionsTheme: const PageTransitionsTheme(
              // builders: { TargetPlatform.android: PredictiveBackPageTransitionsBuilder() },
            // ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
            // pageTransitionsTheme: const PageTransitionsTheme(
              // builders: { TargetPlatform.android: PredictiveBackPageTransitionsBuilder() },
            // ),
          ),
          themeMode: EasyDynamicTheme.of(context).themeMode,
          routerConfig: router,
        );
      },
    );
  }
}
