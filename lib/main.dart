import 'package:dft/src/about.dart';
import 'package:dft/src/home.dart';
import 'package:dft/theme/theme_service.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  await GetStorage.init();
  runApp(MyApp());
}

const _fallbackGreen = Color(0xFF386A20);

class MyApp extends StatelessWidget {
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

        return GetMaterialApp(
          title: 'DFT Calculator',
          theme: ThemeData(colorScheme: lightColorScheme, useMaterial3: true),
          darkTheme: ThemeData(colorScheme: darkColorScheme, useMaterial3: true),
          themeMode: ThemeService().getThemeMode(),
          home: const DarkModeHome(),
        );
      },
    );
  }
}

class DarkModeHome extends StatefulWidget {
  const DarkModeHome({super.key});

  @override
  _DarkModeHomeState createState() => _DarkModeHomeState();
}

class _DarkModeHomeState extends State<DarkModeHome> {
  bool value = ThemeService().isSavedDarkMode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        elevation: 5,
        title: const Text('DFT Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Get.to(() => const AboutPage()),
            iconSize: 24,
          ),
          Switch(
            value: value,
            onChanged: (value) => setState(() {
              this.value = value;
              ThemeService().changeThemeMode(value);
            }),
          ),
        ],
      ),
      body: const HomeScreen(),
    );
  }
}
