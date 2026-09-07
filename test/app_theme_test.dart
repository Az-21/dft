import 'package:dft/app.dart';
import 'package:dft/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Pumps the full app; DynamicColorBuilder falls back to seed schemes in tests
Future<void> pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await ThemeController.init();
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
}

void main() {
  test('ThemeController persists the selected mode', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final controller = await ThemeController.init(prefs: prefs);
    expect(controller.value, ThemeMode.system);

    await controller.set(ThemeMode.dark);
    final reloaded = await ThemeController.init(prefs: prefs);
    expect(reloaded.value, ThemeMode.dark);

    await controller.set(ThemeMode.system);
  });

  testWidgets('Renders home with doubled text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await pumpApp(tester);
    expect(find.text('DFT Calculator'), findsOneWidget);
  });

  testWidgets('Renders home with doubled text and high contrast', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(highContrast: true);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await pumpApp(tester);
    expect(find.text('DFT Calculator'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });
}
