import "package:complex/complex.dart";
import "package:dft/core/dsp/fourier_transform.dart";
import "package:dft/features/results/result_template.dart";
import "package:flutter/material.dart";

class IDFT extends StatelessWidget {
  final List<Complex> points;

  const IDFT({super.key, required this.points});

  static String appBarTitle = "Inverse DFT";
  static String transformSymbol = "F′";
  static SignalProcessingOperation operation = SignalProcessingOperation.idft;

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
