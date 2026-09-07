import "package:complex/complex.dart";
import "package:dft/core/dsp/fourier_transform.dart";
import "package:dft/features/results/result_template.dart";
import "package:flutter/material.dart";

class DFT extends StatelessWidget {
  final List<Complex> points;

  const DFT({super.key, required this.points});

  static String appBarTitle = "DFT";
  static String transformSymbol = "F";
  static SignalProcessingOperation operation = SignalProcessingOperation.dft;

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
