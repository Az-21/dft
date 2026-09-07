import "package:dft/app.dart";
import "package:dft/theme/theme_controller.dart";
import "package:flutter/material.dart";

/// Thin bootstrap entrypoint
///
/// Startup awaits the persisted theme mode, which is why the binding is
/// initialized here. Application widget lives in `lib/app.dart`, routing in
/// `lib/routing/`, and theming in `lib/theme/`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.init();
  runApp(const MyApp());
}
