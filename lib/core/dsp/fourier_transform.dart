import "dart:math";

import "package:complex/complex.dart";
import "package:meta/meta.dart";

/// Which Fourier transform to apply.
enum SignalProcessingOperation { radix2Fft, dft, idft }

/// Upper bound for the quadratic DFT/IDFT path.
///
/// Beyond this the O(N^2) cost freezes the UI; callers should chunk,
/// downsample, or move work off the UI isolate.
const int maxDftLength = 4096;

/// Upper bound for the (padded) FFT length.
const int maxFftLength = 1 << 20;

/// Immutable result of a transform, including padding metadata for FFT.
///
/// [output] always has length [paddedLength]. When [wasPadded] is true the
/// input was zero-padded from [inputLength] up to [paddedLength].
@immutable
class FourierResult {
  const FourierResult({
    required this.output,
    required this.inputLength,
    required this.paddedLength,
    required this.wasPadded,
  });

  final List<Complex> output;
  final int inputLength;
  final int paddedLength;
  final bool wasPadded;
}

/// A single formatted complex value (presentation boundary only).
typedef FormattedPoint = ({String real, String imaginary});

/// Formats one floating-point component with fixed [precision].
///
/// Normalizes negative zero to positive zero, passes NaN/infinities through
/// as short tokens, and never throws for non-finite input.
String formatComponent(double value, int precision) {
  final int safePrecision = precision.clamp(0, 20);
  if (value.isNaN) return "NaN";
  if (value.isInfinite) return value.isNegative ? "-Inf" : "Inf";
  if (value == 0) return (0.0).toStringAsFixed(safePrecision);
  // Snap tiny denormals/noise to zero so "-0.000" never leaks into the UI.
  final double threshold = 0.5 * pow(10, -safePrecision).toDouble();
  if (value.abs() < threshold) return (0.0).toStringAsFixed(safePrecision);
  return value.toStringAsFixed(safePrecision);
}

/// Formats a signal for display. Returns parallel [real, imaginary] lists to
/// preserve the legacy shape; prefer [formatSignalPoints] for new code.
List<List<String>> signalWithFixedPrecision(List<Complex> signal, int precision) {
  final List<String> realParts = List<String>.filled(signal.length, "");
  final List<String> imaginaryParts = List<String>.filled(signal.length, "");
  for (int index = 0; index < signal.length; index++) {
    realParts[index] = formatComponent(signal[index].real, precision);
    imaginaryParts[index] = formatComponent(signal[index].imaginary, precision);
  }
  return <List<String>>[realParts, imaginaryParts];
}

/// Typed alternative to [signalWithFixedPrecision]: one record per point.
List<FormattedPoint> formatSignalPoints(List<Complex> signal, int precision) {
  return List<FormattedPoint>.generate(
    signal.length,
    (int index) => (
      real: formatComponent(signal[index].real, precision),
      imaginary: formatComponent(signal[index].imaginary, precision),
    ),
    growable: false,
  );
}

/// Formats output in `x(0) = a + (b)i` form.
String printDiscretePoint(String prefix, int index, String re, String im) {
  String pointValue = "$prefix($index) = ";

  // Real part with '-' padding
  re.startsWith("-") ? pointValue += "$re " : pointValue += " $re ";

  // * +/- sign aware imaginary part
  im.startsWith("-") ? pointValue += "- (${im.substring(1)})i" : pointValue += "+ ($im)i";

  return pointValue;
}

/// Returns true for strictly positive powers of two.
bool isPowerOfTwo(int value) {
  return value > 0 && (value & (value - 1)) == 0;
}

/// Smallest power of two greater than or equal to [length].
///
/// Returns 1 for [length] <= 1 and 0 for [length] <= 0 (so empty input
/// stays empty instead of being padded to length 1).
int nextPowerOfTwo(int length) {
  if (length <= 0) return 0;
  if (length == 1) return 1;
  int power = 1;
  while (power < length) {
    power <<= 1;
  }
  return power;
}

/// Returns a new list padded with zeros up to the next power of two.
///
/// Never mutates [signal]: an already power-of-two (or empty) input is
/// returned as a copy. Throws [ArgumentError] if the padded length would
/// exceed [maxFftLength].
List<Complex> padWithZeros(List<Complex> signal) {
  if (signal.isEmpty) return <Complex>[];
  if (isPowerOfTwo(signal.length)) return List<Complex>.of(signal);
  final int paddedLength = nextPowerOfTwo(signal.length);
  if (paddedLength > maxFftLength) {
    throw ArgumentError(
      "Signal length ${signal.length} pads to $paddedLength, "
      "which exceeds maxFftLength ($maxFftLength).",
    );
  }
  return <Complex>[...signal, ...List<Complex>.filled(paddedLength - signal.length, const Complex(0))];
}

/// Twiddle factor exp(-/+ j*2*pi*exponent/size).
///
/// Positive [exponent] gives the inverse (positive-angle) root; the forward
/// FFT uses negative exponents, matching the old `W(-k, N)` call shape.
Complex twiddleFactor(int exponent, int size, {bool inverse = false}) {
  final double angle = 2 * pi * exponent / size * (inverse ? 1 : -1);
  // Note: Complex(0, angle).exp() == Complex(cos(angle), sin(angle)).
  return Complex(cos(angle), sin(angle));
}

/// Legacy name for [twiddleFactor]; prefer [twiddleFactor] in new code.
@Deprecated("Use twiddleFactor instead")
Complex W(int k, int N) => twiddleFactor(-k, N);

void _checkDftLength(int length) {
  if (length > maxDftLength) {
    throw ArgumentError(
      "Signal length $length exceeds maxDftLength ($maxDftLength). "
      "Downsample or use the FFT path instead.",
    );
  }
}

/// Discrete Fourier Transform (or its inverse with [isInverse]).
///
/// Correct for complex input, never mutates [inputSignal], and precomputes
/// the N distinct sine/cosine values (indexed by `(bin * index) % N`)
/// instead of evaluating trig functions N^2 times.
List<Complex> _discreteFourierTransform(List<Complex> inputSignal, {required bool isInverse}) {
  if (inputSignal.isEmpty) return <Complex>[];
  _checkDftLength(inputSignal.length);

  final int length = inputSignal.length;
  final List<double> cosineTable = List<double>.generate(length, (int t) => cos(2 * pi * t / length), growable: false);
  final List<double> sineTable = List<double>.generate(length, (int t) => sin(2 * pi * t / length), growable: false);

  final List<Complex> outputSignal = List<Complex>.filled(length, const Complex(0));

  for (int outputBin = 0; outputBin < length; outputBin++) {
    double sumReal = 0;
    double sumImaginary = 0;
    for (int inputIndex = 0; inputIndex < length; inputIndex++) {
      final int angleIndex = (outputBin * inputIndex) % length;
      final double cosine = cosineTable[angleIndex];
      final double sine = sineTable[angleIndex];
      final double sampleReal = inputSignal[inputIndex].real;
      final double sampleImaginary = inputSignal[inputIndex].imaginary;
      if (isInverse) {
        // Multiply by (cos + j*sin).
        sumReal += sampleReal * cosine - sampleImaginary * sine;
        sumImaginary += sampleReal * sine + sampleImaginary * cosine;
      } else {
        // Multiply by (cos - j*sin).
        sumReal += sampleReal * cosine + sampleImaginary * sine;
        sumImaginary += -sampleReal * sine + sampleImaginary * cosine;
      }
    }
    if (isInverse) {
      sumReal /= length;
      sumImaginary /= length;
    }
    outputSignal[outputBin] = Complex(sumReal, sumImaginary);
  }

  return outputSignal;
}

/// Iterative in-place radix-2 decimation-in-time FFT.
///
/// [paddedSignal] must already be a power-of-two length copy; it is
/// reordered and transformed in place and then returned.
List<Complex> _iterativeFftInPlace(List<Complex> paddedSignal) {
  final int length = paddedSignal.length;
  if (length <= 1) return paddedSignal;

  // Bit-reversal permutation.
  int bitWidth = 0;
  while ((1 << bitWidth) < length) {
    bitWidth++;
  }
  for (int i = 0; i < length; i++) {
    int reversed = 0;
    for (int bit = 0; bit < bitWidth; bit++) {
      reversed = (reversed << 1) | ((i >> bit) & 1);
    }
    if (reversed > i) {
      final Complex temp = paddedSignal[i];
      paddedSignal[i] = paddedSignal[reversed];
      paddedSignal[reversed] = temp;
    }
  }

  // Butterfly stages; twiddle powers are stepped multiplicatively so each
  // stage evaluates cos/sin exactly once.
  for (int size = 2; size <= length; size <<= 1) {
    final double stageAngle = -2 * pi / size;
    final double stageReal = cos(stageAngle);
    final double stageImaginary = sin(stageAngle);
    final int halfSize = size ~/ 2;
    for (int blockStart = 0; blockStart < length; blockStart += size) {
      double twiddleReal = 1;
      double twiddleImaginary = 0;
      for (int j = 0; j < halfSize; j++) {
        final Complex even = paddedSignal[blockStart + j];
        final Complex odd = paddedSignal[blockStart + j + halfSize];
        final double stagedReal = twiddleReal * odd.real - twiddleImaginary * odd.imaginary;
        final double stagedImaginary = twiddleReal * odd.imaginary + twiddleImaginary * odd.real;
        paddedSignal[blockStart + j] = Complex(even.real + stagedReal, even.imaginary + stagedImaginary);
        paddedSignal[blockStart + j + halfSize] = Complex(even.real - stagedReal, even.imaginary - stagedImaginary);
        final double nextReal = twiddleReal * stageReal - twiddleImaginary * stageImaginary;
        twiddleImaginary = twiddleReal * stageImaginary + twiddleImaginary * stageReal;
        twiddleReal = nextReal;
      }
    }
  }

  return paddedSignal;
}

/// Radix-2 FFT with zero padding; never mutates [inputSignal].
List<Complex> _radix2Fft(List<Complex> inputSignal) {
  if (inputSignal.isEmpty) return <Complex>[];
  final List<Complex> paddedSignal = padWithZeros(inputSignal);
  if (paddedSignal.length > maxFftLength) {
    throw ArgumentError(
      "Padded FFT length ${paddedSignal.length} exceeds "
      "maxFftLength ($maxFftLength).",
    );
  }
  if (paddedSignal.length == 1) return List<Complex>.of(paddedSignal);
  return _iterativeFftInPlace(paddedSignal);
}

/// Forward FFT over an already power-of-two [signal].
///
/// Returns a new list and never mutates the input. Throws [ArgumentError]
/// for empty input or lengths that are not a power of two (use
/// [padWithZeros] or [fourierTransform] first).
List<Complex> findFFT(List<Complex> signal) {
  if (signal.isEmpty) {
    throw ArgumentError("findFFT requires a non-empty signal.");
  }
  if (!isPowerOfTwo(signal.length)) {
    throw ArgumentError(
      "findFFT requires a power-of-two length, "
      "got ${signal.length}. Pad with padWithZeros first.",
    );
  }
  if (signal.length == 1) return List<Complex>.of(signal);
  return _iterativeFftInPlace(List<Complex>.of(signal));
}

/// Stem-plot point for the result chart.
///
/// Field names describe the component ([real]/[imaginary]), not a
/// magnitude. Legacy [realMag]/[imgMag] getters remain for compatibility.
class ChartFFT {
  ChartFFT(this.time, this.real, this.imaginary);

  final double imaginary;
  final double real;
  final int time;

  @Deprecated("Use real instead")
  double get realMag => real;

  @Deprecated("Use imaginary instead")
  double get imgMag => imaginary;

  /// Raw (full-precision) chart points derived from [spectrum].
  static List<ChartFFT> fromSpectrum(List<Complex> spectrum) {
    return List<ChartFFT>.generate(
      spectrum.length,
      (int index) => ChartFFT(index, spectrum[index].real, spectrum[index].imaginary),
      growable: false,
    );
  }
}

/// Runs [operation] over [inputSignal] with padding metadata.
///
/// The input list is never mutated. FFT inputs that are not a power of two
/// are zero-padded; DFT/IDFT lengths are used as-is.
FourierResult transformSignal(List<Complex> inputSignal, SignalProcessingOperation operation) {
  switch (operation) {
    case SignalProcessingOperation.radix2Fft:
      if (inputSignal.isEmpty) {
        return const FourierResult(output: <Complex>[], inputLength: 0, paddedLength: 0, wasPadded: false);
      }
      final List<Complex> output = _radix2Fft(inputSignal);
      return FourierResult(
        output: output,
        inputLength: inputSignal.length,
        paddedLength: output.length,
        wasPadded: output.length != inputSignal.length,
      );
    case SignalProcessingOperation.dft:
      return FourierResult(
        output: _discreteFourierTransform(inputSignal, isInverse: false),
        inputLength: inputSignal.length,
        paddedLength: inputSignal.length,
        wasPadded: false,
      );
    case SignalProcessingOperation.idft:
      return FourierResult(
        output: _discreteFourierTransform(inputSignal, isInverse: true),
        inputLength: inputSignal.length,
        paddedLength: inputSignal.length,
        wasPadded: false,
      );
  }
}

/// DFT, IDFT, and Radix-2 FFT handler (legacy output-only shape).
///
/// Prefer [transformSignal] when padding metadata is needed.
List<Complex> fourierTransform(List<Complex> inputSignal, SignalProcessingOperation operation) {
  return transformSignal(inputSignal, operation).output;
}
