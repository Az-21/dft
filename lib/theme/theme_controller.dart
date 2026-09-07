import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

/// Manual [ThemeMode] override persisted across restarts
///
/// Defaults to [ThemeMode.system]; call [ThemeController.init] once in `main` before `runApp`, then read [ThemeController.instance]
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._(super.mode);

  static const storageKey = "themeMode";

  static ThemeController? _instance;

  /// Global instance; assert message points at the missing init call
  static ThemeController get instance {
    final controller = _instance;
    assert(controller != null, "Call ThemeController.init() in main() first");
    return controller!;
  }

  /// Loads the saved mode and publishes the singleton
  static Future<ThemeController> init({SharedPreferences? prefs}) async {
    final store = prefs ?? await SharedPreferences.getInstance();
    final raw = store.getString(storageKey);
    final saved = ThemeMode.values.firstWhere((each) => each.name == raw, orElse: () => ThemeMode.system);
    final controller = _instance ?? ThemeController._(saved);
    controller.value = saved;
    _instance = controller;
    return controller;
  }

  /// Persists [mode] and notifies listeners
  Future<void> set(ThemeMode mode) async {
    value = mode;
    final store = await SharedPreferences.getInstance();
    await store.setString(storageKey, mode.name);
  }

  /// Cycles system -> light -> dark -> system
  Future<void> cycle() {
    return switch (value) {
      ThemeMode.system => set(ThemeMode.light),
      ThemeMode.light => set(ThemeMode.dark),
      ThemeMode.dark => set(ThemeMode.system),
    };
  }
}
