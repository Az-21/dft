// * Service to keep track of user's theme preference

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ThemeService {
  final _getStorage = GetStorage();

  void changeThemeMode(bool value) {
    // value from switch
    if (value) {
      Get.changeThemeMode(ThemeMode.dark);
      saveThemeMode(true);
    } else {
      Get.changeThemeMode(ThemeMode.light);
      saveThemeMode(false);
    }
    // Get.changeThemeMode(isSavedDarkMode() ? ThemeMode.dark : ThemeMode.light);
    // saveThemeMode(!isSavedDarkMode());
  }

  ThemeMode getThemeMode() {
    return isSavedDarkMode() ? ThemeMode.dark : ThemeMode.light;
  }

  bool isSavedDarkMode() {
    return _getStorage.read('isDarkMode') ?? true;
  }

  void saveThemeMode(bool isDarkMode) {
    _getStorage.write('isDarkMode', isDarkMode);
  }
}
