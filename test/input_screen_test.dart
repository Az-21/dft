import "package:dft/app.dart";
import "package:dft/routing/app_router.dart";
import "package:dft/routing/app_routes.dart";
import "package:dft/theme/theme_controller.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

Future<void> pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await ThemeController.init();
  await tester.pumpWidget(const MyApp());
  // The router is a global singleton: a previous test may have navigated
  // away, so always return to the input screen before asserting.
  router.go(AppRoutes.home);
  await tester.pumpAndSettle();
}

int realFieldCount() => find.textContaining("Real part of x(").evaluate().length;

void main() {
  testWidgets("renders a single point with transform actions", (tester) async {
    await pumpApp(tester);
    expect(find.text("DFT Calculator"), findsOneWidget);
    expect(realFieldCount(), 1);
    expect(find.text("IDFT"), findsOneWidget);
    expect(find.text("DFT"), findsOneWidget);
    expect(find.text("FFT"), findsOneWidget);
  });

  testWidgets("add and remove buttons change the row count", (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip("Add point"));
    await tester.pumpAndSettle();
    expect(realFieldCount(), 2);

    await tester.tap(find.byTooltip("Remove last point"));
    await tester.pumpAndSettle();
    expect(realFieldCount(), 1);
  });

  testWidgets("removing the last remaining point is refused", (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip("Remove last point"));
    await tester.pumpAndSettle();
    expect(realFieldCount(), 1);
    expect(find.text("At least one point is required"), findsOneWidget);
  });

  testWidgets("invalid input blocks navigation and shows an error", (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextFormField).first, "-");
    await tester.pump();
    await tester.tap(find.text("DFT"));
    await tester.pumpAndSettle();
    // Still on the input screen with an inline validation error.
    expect(find.text("DFT Calculator"), findsOneWidget);
    expect(find.text("Enter a valid number"), findsOneWidget);
    expect(find.text("Graphical Result"), findsNothing);
  });

  testWidgets("valid input navigates to the DFT result", (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextFormField).first, "1");
    await tester.pump();
    await tester.tap(find.text("DFT"));
    await tester.pumpAndSettle();
    expect(find.text("Graphical Result"), findsOneWidget);
  });

  testWidgets("example loader replaces the input", (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip("Input actions"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Load cosine example"));
    await tester.pumpAndSettle();
    // The list is lazy: drag it until the final row is built.
    for (int i = 0; i < 6 && find.text("Real part of x(7)").evaluate().isEmpty; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    expect(find.text("Real part of x(7)"), findsWidgets);
  });

  testWidgets("keyboard toolbar offers Next and Done while editing", (tester) async {
    addTearDown(tester.view.reset);
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    await pumpApp(tester);
    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();
    expect(find.text("Previous"), findsOneWidget);
    expect(find.text("Next"), findsOneWidget);
    expect(find.text("Done"), findsOneWidget);

    // Done confirms editing and dismisses the keyboard.
    await tester.tap(find.text("Done"));
    await tester.pump();
    expect(find.text("Done"), findsNothing);
  });

  testWidgets("Next moves focus to the following field", (tester) async {
    addTearDown(tester.view.reset);
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    await pumpApp(tester);
    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();

    bool previousEnabled() => tester.widget<TextButton>(find.widgetWithText(TextButton, "Previous")).enabled;
    expect(previousEnabled(), isFalse);

    await tester.tap(find.text("Next"));
    await tester.pump();
    expect(previousEnabled(), isTrue);
  });
}
