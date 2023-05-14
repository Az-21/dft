import 'package:dft/src/about.dart';
import 'package:dft/src/home.dart';
import 'package:dft/theme/theme.dart';
import 'package:dft/theme/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  await GetStorage.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'DFT Calculator',
      theme: Themes().lightTheme,
      darkTheme: Themes().darkTheme,
      themeMode: ThemeService().getThemeMode(),
      home: const DarkModeHome(),
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
