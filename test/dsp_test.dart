import "dart:math";

import "package:complex/complex.dart";
import "package:dft/core/dsp/fourier_transform.dart";
import "package:flutter_test/flutter_test.dart";

void expectComplex(Complex actual, Complex expected, {double tolerance = 1e-9}) {
  expect(
    (actual.real - expected.real).abs() < tolerance && (actual.imaginary - expected.imaginary).abs() < tolerance,
    isTrue,
    reason: "expected $expected, got $actual",
  );
}

void main() {
  group("isPowerOfTwo", () {
    test("rejects zero and negatives", () {
      expect(isPowerOfTwo(0), isFalse);
      expect(isPowerOfTwo(-1), isFalse);
      expect(isPowerOfTwo(-8), isFalse);
    });

    test("accepts powers of two only", () {
      expect(isPowerOfTwo(1), isTrue);
      expect(isPowerOfTwo(2), isTrue);
      expect(isPowerOfTwo(4), isTrue);
      expect(isPowerOfTwo(1024), isTrue);
      expect(isPowerOfTwo(3), isFalse);
      expect(isPowerOfTwo(6), isFalse);
      expect(isPowerOfTwo(100), isFalse);
    });
  });

  group("nextPowerOfTwo / padWithZeros", () {
    test("empty stays empty", () {
      expect(nextPowerOfTwo(0), 0);
      expect(padWithZeros(<Complex>[]), isEmpty);
    });

    test("power-of-two input returns an equal copy, not the same list", () {
      final List<Complex> input = <Complex>[const Complex(1), const Complex(2)];
      final List<Complex> padded = padWithZeros(input);
      expect(padded, hasLength(2));
      expect(identical(padded, input), isFalse);
    });

    test("pads 3 points to 4 and 5 points to 8", () {
      final List<Complex> three = List<Complex>.filled(3, const Complex(1));
      expect(padWithZeros(three), hasLength(4));
      final List<Complex> five = List<Complex>.filled(5, const Complex(1));
      final List<Complex> padded = padWithZeros(five);
      expect(padded, hasLength(8));
      expect(padded.sublist(5), everyElement(const Complex(0)));
    });

    test("never mutates the input", () {
      final List<Complex> input = <Complex>[const Complex(1), const Complex(2), const Complex(3)];
      padWithZeros(input);
      expect(input, hasLength(3));
    });
  });

  group("DFT known vectors", () {
    test("impulse maps to all ones", () {
      final List<Complex> output = fourierTransform(<Complex>[
        const Complex(1),
        const Complex(0),
        const Complex(0),
        const Complex(0),
      ], SignalProcessingOperation.dft);
      expect(output, hasLength(4));
      for (final Complex point in output) {
        expectComplex(point, const Complex(1));
      }
    });

    test("constant maps to N at bin 0", () {
      final List<Complex> output = fourierTransform(
        List<Complex>.filled(4, const Complex(1)),
        SignalProcessingOperation.dft,
      );
      expectComplex(output[0], const Complex(4));
      for (int i = 1; i < 4; i++) {
        expectComplex(output[i], const Complex(0));
      }
    });

    test("single point is identity (DFT) and identity (IDFT)", () {
      const Complex point = Complex(3, -2);
      expectComplex(fourierTransform(<Complex>[point], SignalProcessingOperation.dft)[0], point);
      expectComplex(fourierTransform(<Complex>[point], SignalProcessingOperation.idft)[0], point);
    });

    test("complex input uses the correct forward sign", () {
      // x = [0, j, 0, 0]; X[1] = j * e^{-j*pi/2} = j * (-j) = 1.
      // The old code computed re as rk*cos - ik*sin and returned -1 here.
      final List<Complex> output = fourierTransform(<Complex>[
        const Complex(0),
        const Complex(0, 1),
        const Complex(0),
        const Complex(0),
      ], SignalProcessingOperation.dft);
      expectComplex(output[1], const Complex(1));
      expectComplex(output[3], const Complex(-1));
    });

    test("IDFT scales by 1/N", () {
      final List<Complex> output = fourierTransform(<Complex>[
        const Complex(4),
        const Complex(0),
        const Complex(0),
        const Complex(0),
      ], SignalProcessingOperation.idft);
      for (final Complex point in output) {
        expectComplex(point, const Complex(1));
      }
    });

    test("empty input returns empty output", () {
      expect(fourierTransform(<Complex>[], SignalProcessingOperation.dft), isEmpty);
      expect(fourierTransform(<Complex>[], SignalProcessingOperation.idft), isEmpty);
      expect(fourierTransform(<Complex>[], SignalProcessingOperation.radix2Fft), isEmpty);
    });

    test("oversized DFT input throws", () {
      expect(
        () => fourierTransform(List<Complex>.filled(maxDftLength + 1, const Complex(1)), SignalProcessingOperation.dft),
        throwsArgumentError,
      );
    });
  });

  group("FFT", () {
    test("agrees with DFT on power-of-two lengths", () {
      final List<Complex> input = <Complex>[
        const Complex(1, 1),
        const Complex(2, -1),
        const Complex(0, 3),
        const Complex(-2, 0.5),
        const Complex(1.5, 1.5),
        const Complex(0, -2),
        const Complex(3),
        const Complex(-1, -1),
      ];
      final List<Complex> viaDft = fourierTransform(input, SignalProcessingOperation.dft);
      final List<Complex> viaFft = fourierTransform(input, SignalProcessingOperation.radix2Fft);
      expect(viaFft, hasLength(viaDft.length));
      for (int i = 0; i < viaDft.length; i++) {
        expectComplex(viaFft[i], viaDft[i]);
      }
    });

    test("pads non-power-of-two input and reports metadata", () {
      final List<Complex> input = <Complex>[const Complex(1), const Complex(2), const Complex(3)];
      final FourierResult result = transformSignal(input, SignalProcessingOperation.radix2Fft);
      expect(result.inputLength, 3);
      expect(result.paddedLength, 4);
      expect(result.wasPadded, isTrue);
      expect(result.output, hasLength(4));
      // Display input must not have been mutated by the transform.
      expect(input, hasLength(3));
    });

    test("un-padded input reports wasPadded=false", () {
      final FourierResult result = transformSignal(<Complex>[
        const Complex(1),
        const Complex(2),
      ], SignalProcessingOperation.radix2Fft);
      expect(result.wasPadded, isFalse);
      expect(result.paddedLength, 2);
    });

    test("findFFT rejects empty and non-power-of-two input", () {
      expect(() => findFFT(<Complex>[]), throwsArgumentError);
      expect(() => findFFT(<Complex>[const Complex(1), const Complex(2), const Complex(3)]), throwsArgumentError);
    });

    test("findFFT never mutates its input", () {
      final List<Complex> input = <Complex>[const Complex(1), const Complex(-1)];
      final List<Complex> output = findFFT(input);
      expect(input, <Complex>[const Complex(1), const Complex(-1)]);
      expect(output, hasLength(2));
    });
  });

  group("FFT known vectors", () {
    test("impulse maps to all ones", () {
      final List<Complex> input = List<Complex>.filled(8, const Complex(0));
      input[0] = const Complex(1);
      final List<Complex> output = fourierTransform(input, SignalProcessingOperation.radix2Fft);
      expect(output, hasLength(8));
      for (final Complex point in output) {
        expectComplex(point, const Complex(1));
      }
    });

    test("constant maps to N at bin 0", () {
      final List<Complex> output = fourierTransform(
        List<Complex>.filled(8, const Complex(1)),
        SignalProcessingOperation.radix2Fft,
      );
      expectComplex(output[0], const Complex(8));
      for (int i = 1; i < 8; i++) {
        expectComplex(output[i], const Complex(0));
      }
    });

    test("pure imaginary constant scales bin 0", () {
      final List<Complex> output = fourierTransform(
        List<Complex>.filled(4, const Complex(0, 1)),
        SignalProcessingOperation.radix2Fft,
      );
      expectComplex(output[0], const Complex(0, 4));
      for (int i = 1; i < 4; i++) {
        expectComplex(output[i], const Complex(0));
      }
    });

    test("length-2 FFT is sum and difference", () {
      const Complex a = Complex(1, 2);
      const Complex b = Complex(3, -1);
      final List<Complex> output = fourierTransform(<Complex>[a, b], SignalProcessingOperation.radix2Fft);
      expectComplex(output[0], const Complex(4, 1));
      expectComplex(output[1], const Complex(-2, 3));
    });

    test("alternating input concentrates at the Nyquist bin", () {
      final List<Complex> output = fourierTransform(<Complex>[
        const Complex(1),
        const Complex(-1),
        const Complex(1),
        const Complex(-1),
      ], SignalProcessingOperation.radix2Fft);
      expectComplex(output[0], const Complex(0));
      expectComplex(output[1], const Complex(0));
      expectComplex(output[2], const Complex(4));
      expectComplex(output[3], const Complex(0));
    });

    test("cosine at bin 1 splits across bins 1 and N-1", () {
      const int length = 8;
      final List<Complex> input = List<Complex>.generate(length, (int n) => Complex(cos(2 * pi * n / length)));
      final List<Complex> output = fourierTransform(input, SignalProcessingOperation.radix2Fft);
      expectComplex(output[1], const Complex(4));
      expectComplex(output[length - 1], const Complex(4));
      for (int i = 0; i < length; i++) {
        if (i == 1 || i == length - 1) continue;
        expectComplex(output[i], const Complex(0));
      }
    });

    test("single point is identity", () {
      const Complex point = Complex(3, -2);
      final List<Complex> output = fourierTransform(<Complex>[point], SignalProcessingOperation.radix2Fft);
      expect(output, hasLength(1));
      expectComplex(output[0], point);
    });
  });

  group("FFT properties", () {
    test("is linear: FFT(a + b) == FFT(a) + FFT(b)", () {
      final List<Complex> a = <Complex>[
        const Complex(1, 1),
        const Complex(2, -1),
        const Complex(0, 3),
        const Complex(-2, 0.5),
      ];
      final List<Complex> b = <Complex>[
        const Complex(0.5, -2),
        const Complex(-1, 1),
        const Complex(3),
        const Complex(1, 1),
      ];
      final List<Complex> sum = List<Complex>.generate(4, (int i) => a[i] + b[i]);
      final List<Complex> fftSum = fourierTransform(sum, SignalProcessingOperation.radix2Fft);
      final List<Complex> fftA = fourierTransform(a, SignalProcessingOperation.radix2Fft);
      final List<Complex> fftB = fourierTransform(b, SignalProcessingOperation.radix2Fft);
      for (int i = 0; i < 4; i++) {
        expectComplex(fftSum[i], fftA[i] + fftB[i]);
      }
    });

    test("real input yields conjugate-symmetric spectrum", () {
      final List<Complex> input = <Complex>[
        const Complex(1),
        const Complex(2),
        const Complex(-1),
        const Complex(0.5),
        const Complex(3),
        const Complex(-2),
        const Complex(1.5),
        const Complex(0),
      ];
      final List<Complex> output = fourierTransform(input, SignalProcessingOperation.radix2Fft);
      for (int k = 1; k < input.length; k++) {
        final Complex mirrored = output[input.length - k];
        expect((mirrored.real - output[k].real).abs() < 1e-9, isTrue);
        expect((mirrored.imaginary + output[k].imaginary).abs() < 1e-9, isTrue);
      }
    });

    test("DC and Nyquist bins of real input are real", () {
      final List<Complex> input = <Complex>[const Complex(1), const Complex(-2), const Complex(3), const Complex(0.5)];
      final List<Complex> output = fourierTransform(input, SignalProcessingOperation.radix2Fft);
      expect(output[0].imaginary.abs() < 1e-9, isTrue);
      expect(output[2].imaginary.abs() < 1e-9, isTrue);
    });

    test("circular shift rotates each bin phase", () {
      const int length = 8;
      const int shift = 2;
      final List<Complex> input = List<Complex>.generate(length, (int n) => Complex((n * 1.5 - 3).toDouble()));
      final List<Complex> shifted = List<Complex>.generate(length, (int n) => input[(n - shift) % length]);
      final List<Complex> base = fourierTransform(input, SignalProcessingOperation.radix2Fft);
      final List<Complex> actual = fourierTransform(shifted, SignalProcessingOperation.radix2Fft);
      for (int k = 0; k < length; k++) {
        final double angle = -2 * pi * k * shift / length;
        final Complex rotator = Complex(cos(angle), sin(angle));
        final Complex expected = Complex(
          base[k].real * rotator.real - base[k].imaginary * rotator.imaginary,
          base[k].real * rotator.imaginary + base[k].imaginary * rotator.real,
        );
        expectComplex(actual[k], expected);
      }
    });

    test("matches DFT on seeded random input (N=16)", () {
      final Random rng = Random(42);
      final List<Complex> input = List<Complex>.generate(
        16,
        (_) => Complex(rng.nextDouble() * 4 - 2, rng.nextDouble() * 4 - 2),
      );
      final List<Complex> viaDft = fourierTransform(input, SignalProcessingOperation.dft);
      final List<Complex> viaFft = fourierTransform(input, SignalProcessingOperation.radix2Fft);
      for (int i = 0; i < input.length; i++) {
        expectComplex(viaFft[i], viaDft[i]);
      }
    });

    test("matches DFT on seeded random input (N=32)", () {
      final Random rng = Random(7);
      final List<Complex> input = List<Complex>.generate(
        32,
        (_) => Complex(rng.nextDouble() * 2 - 1, rng.nextDouble() * 2 - 1),
      );
      final List<Complex> viaDft = fourierTransform(input, SignalProcessingOperation.dft);
      final List<Complex> viaFft = fourierTransform(input, SignalProcessingOperation.radix2Fft);
      for (int i = 0; i < input.length; i++) {
        expectComplex(viaFft[i], viaDft[i]);
      }
    });

    test("IDFT(FFT(x)) recovers power-of-two input", () {
      final List<Complex> input = <Complex>[
        const Complex(1, 2),
        const Complex(-3, 0.5),
        const Complex(0, -1),
        const Complex(2.5, 2.5),
        const Complex(1, -1),
        const Complex(0, 2),
        const Complex(-0.5, -0.5),
        const Complex(4),
      ];
      final List<Complex> spectrum = fourierTransform(input, SignalProcessingOperation.radix2Fft);
      final List<Complex> recovered = fourierTransform(spectrum, SignalProcessingOperation.idft);
      for (int i = 0; i < input.length; i++) {
        expectComplex(recovered[i], input[i]);
      }
    });

    test("preserves Parseval energy", () {
      final List<Complex> input = <Complex>[
        const Complex(1),
        const Complex(2),
        const Complex(3),
        const Complex(4),
        const Complex(-1),
        const Complex(0.5),
        const Complex(2.5),
        const Complex(-3),
      ];
      final List<Complex> spectrum = fourierTransform(input, SignalProcessingOperation.radix2Fft);
      double timeEnergy = 0;
      double freqEnergy = 0;
      for (int i = 0; i < input.length; i++) {
        timeEnergy += input[i].real * input[i].real + input[i].imaginary * input[i].imaginary;
        freqEnergy += spectrum[i].real * spectrum[i].real + spectrum[i].imaginary * spectrum[i].imaginary;
      }
      expect((freqEnergy / input.length - timeEnergy).abs() < 1e-9, isTrue);
    });

    test("returns a fresh list on every call", () {
      final List<Complex> input = <Complex>[const Complex(1), const Complex(-1)];
      final List<Complex> first = fourierTransform(input, SignalProcessingOperation.radix2Fft);
      first[0] = const Complex(999);
      final List<Complex> second = fourierTransform(input, SignalProcessingOperation.radix2Fft);
      expect(identical(first, second), isFalse);
      expectComplex(second[0], const Complex(0));
    });
  });

  group("IDFT", () {
    test("impulse spectrum spreads to 1/N", () {
      final List<Complex> output = fourierTransform(<Complex>[
        const Complex(1),
        const Complex(0),
        const Complex(0),
        const Complex(0),
      ], SignalProcessingOperation.idft);
      for (final Complex point in output) {
        expectComplex(point, const Complex(0.25));
      }
    });

    test("explicit N=2 values", () {
      final List<Complex> output = fourierTransform(<Complex>[
        const Complex(2),
        const Complex(2),
      ], SignalProcessingOperation.idft);
      expectComplex(output[0], const Complex(2));
      expectComplex(output[1], const Complex(0));
    });

    test("DFT(IDFT(X)) recovers the spectrum", () {
      final List<Complex> spectrum = <Complex>[
        const Complex(4, -1),
        const Complex(0, 2),
        const Complex(-2, 0.5),
        const Complex(1, 1),
        const Complex(0),
        const Complex(3, -3),
      ];
      final List<Complex> time = fourierTransform(spectrum, SignalProcessingOperation.idft);
      final List<Complex> recovered = fourierTransform(time, SignalProcessingOperation.dft);
      for (int i = 0; i < spectrum.length; i++) {
        expectComplex(recovered[i], spectrum[i]);
      }
    });

    test("is linear", () {
      final List<Complex> a = <Complex>[const Complex(1, 1), const Complex(2, -1)];
      final List<Complex> b = <Complex>[const Complex(-1, 2), const Complex(0.5, 0.5)];
      final List<Complex> sum = <Complex>[a[0] + b[0], a[1] + b[1]];
      final List<Complex> idftSum = fourierTransform(sum, SignalProcessingOperation.idft);
      final List<Complex> idftA = fourierTransform(a, SignalProcessingOperation.idft);
      final List<Complex> idftB = fourierTransform(b, SignalProcessingOperation.idft);
      for (int i = 0; i < 2; i++) {
        expectComplex(idftSum[i], idftA[i] + idftB[i]);
      }
    });

    test("conjugating swaps DFT and IDFT: DFT(conj(x)) == conj(IDFT(x))", () {
      final List<Complex> input = <Complex>[const Complex(1, 2), const Complex(-3, 0.5), const Complex(0, -1)];
      final List<Complex> viaIdft = fourierTransform(input, SignalProcessingOperation.idft);
      final List<Complex> conjugated = input.map((Complex p) => Complex(p.real, -p.imaginary)).toList();
      final List<Complex> viaDftOfConj = fourierTransform(conjugated, SignalProcessingOperation.dft);
      // IDFT carries a 1/N scale, so DFT(conj(x)) == N * conj(IDFT(x)).
      final double length = input.length.toDouble();
      for (int i = 0; i < input.length; i++) {
        expect((viaDftOfConj[i].real - viaIdft[i].real * length).abs() < 1e-9, isTrue);
        expect((viaDftOfConj[i].imaginary + viaIdft[i].imaginary * length).abs() < 1e-9, isTrue);
      }
    });

    test("matches naive scaling on a cosine spectrum", () {
      // Spectrum with energy only at bins 1 and N-1 inverts to a cosine.
      final List<Complex> spectrum = List<Complex>.filled(8, const Complex(0));
      spectrum[1] = const Complex(4);
      spectrum[7] = const Complex(4);
      final List<Complex> output = fourierTransform(spectrum, SignalProcessingOperation.idft);
      for (int n = 0; n < 8; n++) {
        expectComplex(output[n], Complex(cos(2 * pi * n / 8)));
      }
    });

    test("oversized input throws", () {
      expect(
        () =>
            fourierTransform(List<Complex>.filled(maxDftLength + 1, const Complex(1)), SignalProcessingOperation.idft),
        throwsArgumentError,
      );
    });

    test("returns a fresh list on every call", () {
      final List<Complex> input = <Complex>[const Complex(4), const Complex(0)];
      final List<Complex> first = fourierTransform(input, SignalProcessingOperation.idft);
      final List<Complex> second = fourierTransform(input, SignalProcessingOperation.idft);
      expect(identical(first, second), isFalse);
      expect(first, hasLength(2));
      expect(second, hasLength(2));
    });
  });

  group("radix2Fft padding semantics", () {
    test("nextPowerOfTwo covers boundary lengths", () {
      const Map<int, int> cases = <int, int>{
        1: 1,
        2: 2,
        3: 4,
        4: 4,
        5: 8,
        7: 8,
        8: 8,
        9: 16,
        15: 16,
        16: 16,
        17: 32,
        1023: 1024,
        1024: 1024,
      };
      cases.forEach((int input, int expected) {
        expect(nextPowerOfTwo(input), expected, reason: "length $input");
      });
    });

    test("metadata covers lengths 1-9", () {
      const Map<int, int> padded = <int, int>{1: 1, 2: 2, 3: 4, 4: 4, 5: 8, 6: 8, 7: 8, 8: 8, 9: 16};
      padded.forEach((int length, int expectedPadded) {
        final FourierResult result = transformSignal(
          List<Complex>.filled(length, const Complex(1)),
          SignalProcessingOperation.radix2Fft,
        );
        expect(result.inputLength, length, reason: "length $length");
        expect(result.paddedLength, expectedPadded, reason: "length $length");
        expect(result.wasPadded, expectedPadded != length, reason: "length $length");
        expect(result.output, hasLength(expectedPadded));
      });
    });

    test("padded FFT equals DFT of the explicitly zero-padded input", () {
      for (final int length in <int>[3, 5, 6, 7, 9]) {
        final Random rng = Random(length);
        final List<Complex> input = List<Complex>.generate(
          length,
          (_) => Complex(rng.nextDouble() * 4 - 2, rng.nextDouble() * 4 - 2),
        );
        final List<Complex> viaFft = fourierTransform(input, SignalProcessingOperation.radix2Fft);
        final List<Complex> explicitlyPadded = padWithZeros(input);
        final List<Complex> viaDft = fourierTransform(explicitlyPadded, SignalProcessingOperation.dft);
        expect(viaFft, hasLength(explicitlyPadded.length));
        for (int i = 0; i < viaDft.length; i++) {
          expectComplex(viaFft[i], viaDft[i]);
        }
      }
    });

    test("leaves input values untouched", () {
      final List<Complex> input = <Complex>[
        const Complex(1, -1),
        const Complex(2, 2),
        const Complex(-0.5, 0.25),
        const Complex(0, 1),
        const Complex(3),
      ];
      final List<Complex> snapshot = List<Complex>.of(input);
      transformSignal(input, SignalProcessingOperation.radix2Fft);
      expect(input, snapshot);
    });

    test("zero input yields zero output at the padded length", () {
      final FourierResult result = transformSignal(
        List<Complex>.filled(6, const Complex(0)),
        SignalProcessingOperation.radix2Fft,
      );
      expect(result.paddedLength, 8);
      for (final Complex point in result.output) {
        expectComplex(point, const Complex(0));
      }
    });

    test("single point reports no padding", () {
      const Complex point = Complex(2, -5);
      final FourierResult result = transformSignal(<Complex>[point], SignalProcessingOperation.radix2Fft);
      expect(result.wasPadded, isFalse);
      expect(result.paddedLength, 1);
      expectComplex(result.output[0], point);
    });
  });

  group("round trip and energy", () {
    test("IDFT(DFT(x)) approximates x", () {
      final List<Complex> input = <Complex>[
        const Complex(1, 2),
        const Complex(-3, 0.5),
        const Complex(0, -1),
        const Complex(2.5, 2.5),
        const Complex(0),
      ];
      final List<Complex> spectrum = fourierTransform(input, SignalProcessingOperation.dft);
      final List<Complex> recovered = fourierTransform(spectrum, SignalProcessingOperation.idft);
      for (int i = 0; i < input.length; i++) {
        expectComplex(recovered[i], input[i]);
      }
    });

    test("Parseval energy is preserved", () {
      final List<Complex> input = <Complex>[const Complex(1), const Complex(2), const Complex(3), const Complex(4)];
      final List<Complex> spectrum = fourierTransform(input, SignalProcessingOperation.dft);
      double timeEnergy = 0;
      double freqEnergy = 0;
      for (int i = 0; i < input.length; i++) {
        timeEnergy += input[i].real * input[i].real + input[i].imaginary * input[i].imaginary;
        freqEnergy += spectrum[i].real * spectrum[i].real + spectrum[i].imaginary * spectrum[i].imaginary;
      }
      expect((freqEnergy / input.length - timeEnergy).abs() < 1e-9, isTrue);
    });
  });

  group("twiddleFactor", () {
    test("W(0, N) is 1 and W(N/2, N) is -1", () {
      expectComplex(twiddleFactor(0, 4), const Complex(1));
      expectComplex(twiddleFactor(2, 4), const Complex(-1), tolerance: 1e-12);
    });
  });

  group("precision formatting", () {
    test("normalizes negative zero", () {
      expect(formatComponent(-0.0, 3), "0.000");
      expect(formatComponent(double.parse("-0.0004"), 3), "0.000");
    });

    test("passes NaN and infinities through", () {
      expect(formatComponent(double.nan, 3), "NaN");
      expect(formatComponent(double.infinity, 2), "Inf");
      expect(formatComponent(double.negativeInfinity, 2), "-Inf");
    });

    test("signalWithFixedPrecision keeps parallel shape", () {
      final List<List<String>> formatted = signalWithFixedPrecision(<Complex>[const Complex(1.23456, -0.00001)], 3);
      expect(formatted, hasLength(2));
      expect(formatted[0], ["1.235"]);
      expect(formatted[1], ["0.000"]);
    });
  });

  group("ChartFFT", () {
    test("fromSpectrum keeps full precision (no string round-trip)", () {
      final List<Complex> spectrum = <Complex>[const Complex(1.23456789, -9.87654321)];
      final List<ChartFFT> points = ChartFFT.fromSpectrum(spectrum);
      expect(points, hasLength(1));
      expect(points[0].real, 1.23456789);
      expect(points[0].imaginary, -9.87654321);
    });
  });
}
