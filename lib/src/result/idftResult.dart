import 'package:dft/src/functions.dart';
import 'package:dft/src/result/resultTemplate.dart';
import 'package:flutter/material.dart';

class IDFT extends StatelessWidget {
  final List<List<TextEditingController>> points;
  const IDFT({super.key, required this.points});

  static String appBarTitle = "Inverse DFT";
  static String transformSymbol = "F′";
  static SignalProcessingOperation operation = SignalProcessingOperation.opIDFT;

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
