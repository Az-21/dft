import 'dart:math';
import 'package:complex/complex.dart';

enum SignalProcessingOperation { opRadix2FFT, opDFT, opIDFT }

/// Format output in `x(0) = a + (b)i` format
String printDiscretePoint(String prefix, int index, String real, String img) {
  String pointValue = '$prefix($index) = ';

  /// * Real part with '-' padding
  real.startsWith('-') ? pointValue += '$real ' : pointValue += ' $real ';

  /// * +/- sign aware imaginary part
  img.startsWith('-') ? pointValue += '- (${img.substring(1)})i' : pointValue += '+ ($img)i';

  return pointValue;
}

/// Private f(x):=DiscreteFourierTransform(signal, isInverse flag) | Uses standard notation N, n, k
List<Complex> _discreteFourierTransform(final List<Complex> inputSignal, {required bool isInverse}) {
  final N = inputSignal.length;
  List<Complex> outputSignal = List.empty();

  for (int n = 0; n < N; n++) {
    double re = 0;
    double im = 0;

    // Sigma DFT
    for (int k = 0; k < N; k++) {
      final double theta = 2 * pi * n * k / N;
      re += inputSignal[k].real * cos(theta) - inputSignal[k].imaginary * sin(theta);
      im += inputSignal[k].real * sin(theta) + inputSignal[k].imaginary * cos(theta);
    }

    // Extra scaling step to convert Sigma DFT -> Sigma IDFT
    if (isInverse) {
      re /= N;
      im /= N;
    }

    outputSignal.add(Complex(re, im));
  }

  return outputSignal;
}

/// Private f(x):=FFT(signal)
List<Complex> _radix2FFT(List<Complex> inputSignal) {
  // Add padding if necessary
  if (!isPowerOfTwo(inputSignal.length)) {
    inputSignal = padWithZeros(inputSignal);
  }

  return findFFT(inputSignal);
}

// Function to check 2^n binning length required for Rx2FFT
bool isPowerOfTwo(int num) {
  // 8 = 1000
  // 7 = 0111
  // & = 0000
  // ignore: avoid_bool_literals_in_conditional_expressions
  return (num & num - 1 == 0) ? true : false;
}

// Function to pad signal with zeros
List<Complex> padWithZeros(List<Complex> f) {
  final int N = f.length;
  // 2 ^ (log(N)/log(2)) -> nearest 2^n
  final int nextPowerOfTwo = pow(2, (log(N) / log(2)).ceil()).toInt();
  final int paddingReqd = nextPowerOfTwo - N;

  return f + List<Complex>.filled(paddingReqd, const Complex(0, 0));
}

// Twiddle Factor Generator W_N^{k}
Complex W(int k, int N) {
  final Complex W = Complex(0, 2 * pi * k / N).exp();
  return W;
}

// Radix2 FFT Algorithm
List<Complex> findFFT(List<Complex> f) {
  final int N = f.length; // length of half split
  if (N <= 1) {
    // Only 1 element exists => further split is not possible
    return f;
  }

  // Init Lists for even and odd half splits
  final List<Complex> halfOdd = List.empty();
  final List<Complex> halfEven = List.empty();

  // Get even elements from {super:f}
  for (int i = 0; i < N; i += 2) {
    halfEven.add(f[i]);
  }

  // Get odd elements from {super:f}
  for (int i = 1; i < N; i += 2) {
    halfOdd.add(f[i]);
  }

  // Iterative Radix2 FFT [super:f] -> [f:even][f:odd]
  // Decimation
  final List<Complex> even = findFFT(halfEven);
  final List<Complex> odd = findFFT(halfOdd);

  // Init currentFFT = [0+0i, 0+0i, ... , 0+0i];
  final List<Complex> currentFFT = List<Complex>.filled(N, const Complex(0, 0));

  // NOTE: in Dart, (number ~/ 2) == (number / 2).toInt
  final int d = N ~/ 2; // decimated length to gain advantage of W_N -> W_N/2

  for (int k = 0; k < d; k++) {
    // ignore: non_constant_identifier_names
    final Complex W_kN = W(-1 * k, N); // Get W from twiddle factor generator

    /* FFT by decimation
          X(k +  0 ) = G[k] + W * H[k]
          X(k + N/2) = G[k] - W * H[k]
    */
    currentFFT[k + 0] = even[k] + W_kN * odd[k];
    currentFFT[k + d] = even[k] - W_kN * odd[k];
  }

  // Return decimated FFT to iterative caller, or final FFT to main()
  return currentFFT;
}

// Syncfusion chart format
class ChartFFT {
  ChartFFT(this.time, this.realMag, this.imgMag);

  final double imgMag;
  final double realMag;
  final int time;
}

// Private f(x):=FFT(signal)
List<List<String>> resultFFT(List<Complex> inputSignal, int precision, SignalProcessingOperation operation) {
  final List<String> outputReal = List.empty();
  final List<String> outputImg = List.empty();
  List<Complex> outputSignal;

  switch (operation) {
    case SignalProcessingOperation.opRadix2FFT:
      outputSignal = _radix2FFT(inputSignal);
      break;

    case SignalProcessingOperation.opDFT:
      outputSignal = _discreteFourierTransform(inputSignal, isInverse: false);
      break;

    case SignalProcessingOperation.opIDFT:
      outputSignal = _discreteFourierTransform(inputSignal, isInverse: true);
      break;

    default:
      throw Exception("Unimplemented Fourier transform requested");
  }

  for (final Complex complexNum in outputSignal) {
    // Apply fixed precision
    final double real = complexNum.real;
    final String fReal = real.toStringAsFixed(precision);
    final double img = complexNum.imaginary;
    final String fImg = img.toStringAsFixed(precision);

    outputReal.add(fReal);
    outputImg.add(fImg);
  }
  return [outputReal, outputImg];
}
