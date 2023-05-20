import 'package:complex/complex.dart';
import 'package:dft/src/functions.dart';
import 'package:dft/src/result/resultTemplate.dart';
import 'package:flutter/material.dart';

class DFT extends StatelessWidget {
  final List<Complex> points;

  const DFT({super.key, required this.points});

  static String appBarTitle = "DFT";
  static String transformSymbol = "F";
  static SignalProcessingOperation operation = SignalProcessingOperation.opDFT;

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
