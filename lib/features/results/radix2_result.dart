import 'package:complex/complex.dart';
import 'package:dft/core/dsp/fourier_transform.dart';
import 'package:dft/features/results/result_template.dart';
import 'package:flutter/material.dart';

class Radix2FFT extends StatelessWidget {
  final List<Complex> points;

  const Radix2FFT({super.key, required this.points});

  static String appBarTitle = "Radix2 DIF FFT";
  static String transformSymbol = "F₂";
  static SignalProcessingOperation operation =
      SignalProcessingOperation.opRadix2FFT;

  @override
  Widget build(BuildContext context) {
    return ResultsPageTemplate(
      points: points,
      operation: operation,
      appBarTitle: appBarTitle,
      transformSymbol: transformSymbol,
    );
  }
}
