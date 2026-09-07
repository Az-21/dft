import 'package:dft/app.dart';
import 'package:easy_dynamic_theme/easy_dynamic_theme.dart';
import 'package:flutter/material.dart';

/// Thin bootstrap entrypoint.
///
/// Application widget lives in `lib/app.dart` and routing in
/// `lib/routing/` as part of the feature-first layout.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(EasyDynamicThemeWidget(child: const MyApp()));
}
