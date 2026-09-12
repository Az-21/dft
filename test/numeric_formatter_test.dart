import "package:dft/features/input/numeric_formatter.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";

TextEditingValue edit(String oldText, String newText) {
  return const SignedDecimalFormatter().formatEditUpdate(
    TextEditingValue(text: oldText),
    TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    ),
  );
}

void main() {
  group("SignedDecimalFormatter", () {
    test("allows digits, signs, and one dot", () {
      expect(edit("", "3").text, "3");
      expect(edit("", "-").text, "-");
      expect(edit("-", "-2").text, "-2");
      expect(edit("1", "1.").text, "1.");
      expect(edit("1.", "1.5").text, "1.5");
    });

    test("blocks letters, second dots, and exponents", () {
      expect(edit("1", "1a").text, "1");
      expect(edit("1.5", "1.5.").text, "1.5");
      expect(edit("1", "1e").text, "1");
      expect(edit("", "abc").text, "");
    });

    test("collapses redundant leading zeros", () {
      expect(edit("0", "01").text, "1");
      expect(edit("0", "02.5").text, "2.5");
      expect(edit("-0", "-01").text, "-1");
      expect(edit("-0", "-02.5").text, "-2.5");
      expect(edit("0", "00").text, "0");
      expect(edit("00", "002.5").text, "2.5");
    });

    test("keeps meaningful zeros intact", () {
      expect(edit("", "0").text, "0");
      expect(edit("0", "0.").text, "0.");
      expect(edit("0.", "0.5").text, "0.5");
      expect(edit("", "-0.5").text, "-0.5");
      expect(edit("1", "10").text, "10");
      expect(edit("1", "101").text, "101");
    });

    test("keeps the cursor at the end after collapsing", () {
      final TextEditingValue result = edit("0", "01");
      expect(result.text, "1");
      expect(result.selection, const TextSelection.collapsed(offset: 1));
    });
  });
}
