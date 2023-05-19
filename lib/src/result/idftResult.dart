import 'package:dft/src/functions.dart';
import 'package:dft/src/result/resultTemplate.dart';
import 'package:flutter/material.dart';

class IDFT extends StatelessWidget {
  final List<List<TextEditingController>> points;
  const IDFT({super.key, required this.points});

  static String appBarTitle = "IDFT";
  static Uri wikiLink = Uri.parse("https://en.wikipedia.org/wiki/Discrete_Fourier_transform#Inverse_transform");
  static SignalProcessingOperation operation = SignalProcessingOperation.opIDFT;

  @override
  Widget build(BuildContext context) {
    return ResultsPageTemplate(points: points, appBarTitle: appBarTitle, wikiLink: wikiLink, operation: operation);
  }
}
