import 'package:dft/src/functions.dart';
import 'package:dft/src/result/resultTemplate.dart';
import 'package:flutter/material.dart';

class DFT extends StatelessWidget {
  final List<List<TextEditingController>> points;
  const DFT({super.key, required this.points});

  static String appBarTitle = "DFT";
  static Uri wikiLink = Uri.parse("https://en.wikipedia.org/wiki/Discrete_Fourier_transform");
  static SignalProcessingOperation operation = SignalProcessingOperation.opDFT;

  @override
  Widget build(BuildContext context) {
    return ResultsPageTemplate(points: points, appBarTitle: appBarTitle, wikiLink: wikiLink, operation: operation);
  }
}
