import "package:flutter/services.dart";

/// Typing-time rule for signed decimal fields.
///
/// Allows an optional leading "-", digits, and at most one decimal point.
/// Incomplete states ("", "-", ".", "-.") are permitted while typing so the
/// field never fights the user mid-edit; commit-time validation rejects them
/// (see `validateNumericText` in `signal_input.dart`).
///
/// Redundant leading zeros are collapsed as they are typed ("01" becomes "1",
/// "02.5" becomes "2.5") so the field never displays them.
class SignedDecimalFormatter extends TextInputFormatter {
  const SignedDecimalFormatter();

  static final RegExp _valid = RegExp(r"^-?\d*\.?\d*$");
  static final RegExp _leadingZeros = RegExp(r"^(-?)0+(\d)");

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    if (!_valid.hasMatch(newValue.text)) {
      return oldValue;
    }
    final String normalized = newValue.text.replaceFirstMapped(
      _leadingZeros,
      (Match match) => "${match[1]}${match[2]}",
    );
    if (normalized == newValue.text) {
      return newValue;
    }
    final int shift = normalized.length - newValue.text.length;
    final int end = (newValue.selection.end + shift).clamp(0, normalized.length);
    final int start = (newValue.selection.start + shift).clamp(0, normalized.length);
    return newValue.copyWith(
      text: normalized,
      selection: newValue.selection.isValid
          ? TextSelection(baseOffset: start, extentOffset: end)
          : TextSelection.collapsed(offset: normalized.length),
    );
  }
}
