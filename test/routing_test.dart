import "package:complex/complex.dart";
import "package:dft/app.dart";
import "package:dft/routing/app_router.dart";
import "package:dft/routing/transform_params.dart";
import "package:dft/theme/theme_controller.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  group("TransformParams.tryParse", () {
    test("passes typed params through untouched", () {
      final params = TransformParams([const Complex(1, 2)]);
      expect(TransformParams.tryParse(params), same(params));
    });

    test("wraps a typed complex list", () {
      final parsed = TransformParams.tryParse([const Complex(1, 2)]);
      expect(parsed?.points, [const Complex(1, 2)]);
    });

    test("wraps an untyped list of complex values", () {
      final parsed = TransformParams.tryParse(<Object?>[const Complex(1, 2)]);
      expect(parsed?.points, [const Complex(1, 2)]);
    });

    test("rejects null, empty-adjacent, and mismatched payloads", () {
      expect(TransformParams.tryParse(null), isNull);
      expect(TransformParams.tryParse("x(0)"), isNull);
      expect(TransformParams.tryParse([1, 2]), isNull);
      expect(TransformParams.tryParse([const Complex(1, 2), "noise"]), isNull);
    });

    test("exposes an unmodifiable defensive copy", () {
      final source = [const Complex(1, 2)];
      final params = TransformParams(source);
      source.add(const Complex(3, 4));
      expect(params.points, hasLength(1));
      expect(() => params.points.add(const Complex(0)), throwsUnsupportedError);
    });
  });

  testWidgets("Missing transform payload shows the error page", (tester) async {
    SharedPreferences.setMockInitialValues({});
    await ThemeController.init();
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    router.go("/dft");
    await tester.pumpAndSettle();
    expect(find.text("Something went wrong"), findsOneWidget);

    await tester.tap(find.text("Back to input"));
    await tester.pumpAndSettle();
    expect(find.text("DFT Calculator"), findsOneWidget);
  });
}
