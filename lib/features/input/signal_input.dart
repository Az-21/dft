import "dart:convert";
import "dart:math";

import "package:complex/complex.dart";
import "package:dft/core/dsp/fourier_transform.dart";

// Pure, testable input model for the signal entry screen.
// This file must stay Flutter-free so it can be unit tested as plain Dart.

/// One immutable signal sample.
typedef SignalPoint = ({double real, double imaginary});

/// Which component of a point a validation error belongs to.
enum SignalField { real, imaginary }

/// Upper bound for interactive input.
///
/// Keeps long editable lists usable and the O(N^2) DFT path cheap.
/// The DSP core itself supports larger transforms; this cap is UI-only.
const int maxInputPoints = 256;

/// Editable draft of a single point.
///
/// Only plain strings are stored so parsing and validation stay pure and
/// testable. Controllers and focus nodes live in the widget layer and are
/// keyed by [id].
class SignalPointInput {
  SignalPointInput({required this.id, this.real = "0", this.imaginary = "0"});

  final int id;
  String imaginary;
  String real;
}

/// A single validation failure tied to one field of one point.
class FieldError {
  const FieldError({required this.index, required this.field, required this.message});

  final SignalField field;
  final int index;
  final String message;

  @override
  String toString() {
    final String fieldName = field == SignalField.real ? "real part" : "imaginary part";
    return "x($index) $fieldName: $message";
  }
}

/// Result of parsing drafts: valid points plus one error per bad field.
class ParsedSignalInput {
  const ParsedSignalInput({required this.points, required this.errors});

  final List<FieldError> errors;
  final List<Complex> points;

  bool get isValid => errors.isEmpty;
}

/// Commit-time rule for a single text value.
///
/// Intermediate typing states ("", "-", ".", "-.") are tolerated by the
/// input formatter while typing; this validator rejects them when the user
/// submits. Returns an error message, or null when the value is usable.
String? validateNumericText(String? value) {
  final String text = (value ?? "").trim();
  if (text.isEmpty) {
    return "Enter a number";
  }
  final double? parsed = double.tryParse(text);
  if (parsed == null) {
    return "Enter a valid number";
  }
  if (!parsed.isFinite) {
    return "Must be a finite number";
  }
  return null;
}

/// Parses every draft with [double.tryParse].
///
/// Points are only emitted for rows whose *both* fields validate, so callers
/// can rely on `points.length == drafts.length` exactly when there are no errors.
ParsedSignalInput parseSignalInputs(List<SignalPointInput> drafts) {
  final List<Complex> points = <Complex>[];
  final List<FieldError> errors = <FieldError>[];
  for (int index = 0; index < drafts.length; index++) {
    final String? realError = validateNumericText(drafts[index].real);
    final String? imaginaryError = validateNumericText(drafts[index].imaginary);
    if (realError != null) {
      errors.add(FieldError(index: index, field: SignalField.real, message: realError));
    }
    if (imaginaryError != null) {
      errors.add(FieldError(index: index, field: SignalField.imaginary, message: imaginaryError));
    }
    if (realError == null && imaginaryError == null) {
      points.add(Complex(double.parse(drafts[index].real.trim()), double.parse(drafts[index].imaginary.trim())));
    }
  }
  return ParsedSignalInput(points: points, errors: errors);
}

/// Built-in example signals, returned as parsed points.
List<SignalPoint> exampleSignal(String kind) {
  switch (kind) {
    case "impulse":
      return List<SignalPoint>.generate(8, (int n) => (real: n == 0 ? 1 : 0, imaginary: 0));
    case "step":
      return List<SignalPoint>.generate(8, (_) => (real: 1, imaginary: 0));
    case "cosine":
      // x[n] = cos(2*pi*n/8): energy lands on DFT bins 1 and 7.
      return List<SignalPoint>.generate(8, (int n) => (real: cos(2 * pi * n / 8), imaginary: 0));
    default:
      throw ArgumentError('Unknown example "$kind". Use impulse, step, or cosine.');
  }
}

/// Formats an example point for an editable field (parseable, short).
String exampleFieldText(double value) => formatComponent(value, 4);

/// Serializes drafts plus the next free id for state restoration.
String encodeSignalInputs(List<SignalPointInput> drafts, int nextId) {
  return jsonEncode(<String, Object?>{
    "nextId": nextId,
    "points": <List<String>>[
      for (final SignalPointInput draft in drafts) <String>[draft.real, draft.imaginary],
    ],
  });
}

/// Restores drafts serialized with [encodeSignalInputs].
///
/// Returns null when the payload is missing or corrupt, in which case the
/// caller should fall back to the default single-point input. Ids are
/// reassigned sequentially so they stay unique within the session.
({List<SignalPointInput> points, int nextId})? decodeSignalInputs(String raw) {
  if (raw.isEmpty) {
    return null;
  }
  try {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      return null;
    }
    final Object? rows = decoded["points"];
    if (rows is! List || rows.isEmpty) {
      return null;
    }
    final List<SignalPointInput> points = <SignalPointInput>[];
    for (int index = 0; index < rows.length; index++) {
      final Object? row = rows[index];
      if (row is! List || row.length != 2 || row[0] is! String || row[1] is! String) {
        return null;
      }
      points.add(SignalPointInput(id: index, real: row[0] as String, imaginary: row[1] as String));
    }
    if (points.length > maxInputPoints) {
      return null;
    }
    return (points: points, nextId: points.length);
  } on FormatException {
    return null;
  }
}
