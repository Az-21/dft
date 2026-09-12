import "package:dft/features/input/signal_input.dart";
import "package:flutter_test/flutter_test.dart";

SignalPointInput draft({String real = "0", String imaginary = "0"}) {
  return SignalPointInput(id: 0, real: real, imaginary: imaginary);
}

void main() {
  group("validateNumericText", () {
    test("accepts plain, signed, and decimal input", () {
      expect(validateNumericText("0"), isNull);
      expect(validateNumericText("3.25"), isNull);
      expect(validateNumericText("-0.5"), isNull);
      expect(validateNumericText("1e3"), isNull);
      expect(validateNumericText("  2.5  "), isNull);
    });

    test("rejects empty input", () {
      expect(validateNumericText(null), "Enter a number");
      expect(validateNumericText(""), "Enter a number");
      expect(validateNumericText("   "), "Enter a number");
    });

    test("rejects incomplete typing states at commit time", () {
      expect(validateNumericText("-"), "Enter a valid number");
      expect(validateNumericText("."), "Enter a valid number");
      expect(validateNumericText("-."), "Enter a valid number");
      expect(validateNumericText("abc"), "Enter a valid number");
      expect(validateNumericText("1.2.3"), "Enter a valid number");
    });

    test("rejects non-finite values", () {
      expect(validateNumericText("NaN"), "Must be a finite number");
      expect(validateNumericText("Infinity"), "Must be a finite number");
      expect(validateNumericText("-Infinity"), "Must be a finite number");
    });
  });

  group("parseSignalInputs", () {
    test("parses valid drafts into points", () {
      final ParsedSignalInput parsed = parseSignalInputs(<SignalPointInput>[
        draft(real: "1", imaginary: "-2"),
        draft(real: "0.5", imaginary: "0.25"),
      ]);
      expect(parsed.isValid, isTrue);
      expect(parsed.errors, isEmpty);
      expect(parsed.points, hasLength(2));
      expect(parsed.points[0].real, 1);
      expect(parsed.points[0].imaginary, -2);
    });

    test("collects one error per bad field", () {
      final ParsedSignalInput parsed = parseSignalInputs(<SignalPointInput>[
        draft(real: "-", imaginary: "1"),
        draft(real: "2", imaginary: "abc"),
      ]);
      expect(parsed.isValid, isFalse);
      expect(parsed.errors, hasLength(2));
      expect(parsed.errors[0].index, 0);
      expect(parsed.errors[0].field, SignalField.real);
      expect(parsed.errors[1].index, 1);
      expect(parsed.errors[1].field, SignalField.imaginary);
      // Rows with errors contribute no points.
      expect(parsed.points, isEmpty);
    });

    test("keeps valid rows while reporting bad ones", () {
      final ParsedSignalInput parsed = parseSignalInputs(<SignalPointInput>[
        draft(real: "1", imaginary: "1"),
        draft(real: "", imaginary: "2"),
      ]);
      expect(parsed.points, hasLength(1));
      expect(parsed.errors, hasLength(1));
      expect(parsed.errors.single.toString(), contains("x(1)"));
    });
  });

  group("exampleSignal", () {
    test("impulse has a single one", () {
      final List<SignalPoint> signal = exampleSignal("impulse");
      expect(signal, hasLength(8));
      expect(signal[0].real, 1);
      expect(signal.skip(1).every((SignalPoint p) => p.real == 0 && p.imaginary == 0), isTrue);
    });

    test("step is all ones", () {
      final List<SignalPoint> signal = exampleSignal("step");
      expect(signal.every((SignalPoint p) => p.real == 1), isTrue);
    });

    test("cosine starts at one and crosses zero", () {
      final List<SignalPoint> signal = exampleSignal("cosine");
      expect(signal[0].real, moreOrLessEquals(1));
      expect(signal[2].real.abs() < 1e-9, isTrue);
      expect(signal[4].real, moreOrLessEquals(-1));
    });

    test("unknown kind throws", () {
      expect(() => exampleSignal("noise"), throwsArgumentError);
    });

    test("example field text round-trips through the validator", () {
      for (final SignalPoint point in exampleSignal("cosine")) {
        expect(validateNumericText(exampleFieldText(point.real)), isNull);
      }
    });
  });

  group("encode/decodeSignalInputs", () {
    test("round-trips drafts and the next id", () {
      final List<SignalPointInput> drafts = <SignalPointInput>[
        SignalPointInput(id: 0, real: "1.5", imaginary: "-2"),
        SignalPointInput(id: 1, real: "", imaginary: "."),
      ];
      final String raw = encodeSignalInputs(drafts, 2);
      final ({List<SignalPointInput> points, int nextId})? restored = decodeSignalInputs(raw);
      expect(restored, isNotNull);
      expect(restored!.nextId, 2);
      expect(restored.points, hasLength(2));
      expect(restored.points[0].real, "1.5");
      expect(restored.points[1].imaginary, ".");
    });

    test("rejects empty, corrupt, and oversized payloads", () {
      expect(decodeSignalInputs(""), isNull);
      expect(decodeSignalInputs("not json"), isNull);
      expect(decodeSignalInputs('{"points": []}'), isNull);
      expect(decodeSignalInputs('{"points": [["1"]]}'), isNull);
      expect(decodeSignalInputs('{"points": [[1, "0"]]}'), isNull);
    });
  });
}
