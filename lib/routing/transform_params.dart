import "package:complex/complex.dart";
import "package:flutter/foundation.dart";

/// Immutable input payload for the transform result routes
///
/// Points are copied into an unmodifiable list so result screens can neither
/// mutate the caller's data nor observe later edits to it
@immutable
class TransformParams {
  TransformParams(Iterable<Complex> points) : points = List.unmodifiable(points);

  final List<Complex> points;

  /// Parses navigation `extra`, accepting typed params as well as raw complex
  /// lists; returns null for anything else
  static TransformParams? tryParse(Object? extra) {
    if (extra is TransformParams) return extra;
    if (extra is Iterable<Complex>) return TransformParams(extra);
    if (extra is Iterable<Object?> && extra.every((each) => each is Complex)) {
      return TransformParams(extra.cast<Complex>());
    }
    return null;
  }
}
