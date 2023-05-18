import 'package:dft/src/functions.dart';
import 'package:dft/src/result/resultTemplate.dart';
import 'package:flutter/material.dart';

class Radix2FFT extends StatelessWidget {
  final List<List<TextEditingController>> points;
  const Radix2FFT({super.key, required this.points});

  static String appBarTitle = "Radix2 DIF FFT";
  static Uri wikiLink = Uri.parse("https://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm");
  static SignalProcessingOperation operation = SignalProcessingOperation.opRadix2FFT;

  @override
  Widget build(BuildContext context) {
    return ResultsPageTemplate(points: points, appBarTitle: appBarTitle, wikiLink: wikiLink, operation: operation);
  }
}
