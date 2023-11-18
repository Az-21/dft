import 'package:complex/complex.dart';
import 'package:dft/src/functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ResultsPageTemplate extends StatefulWidget {
  const ResultsPageTemplate({
    super.key,
    required this.points,
    required this.operation,
    required this.appBarTitle,
    required this.transformSymbol,
  });

  final String appBarTitle;
  final List<Complex> points;
  final String transformSymbol;
  final SignalProcessingOperation operation;

  @override
  State createState() => _ResultsPageTemplateState();
}

class _ResultsPageTemplateState extends State<ResultsPageTemplate> {
  List<ChartFFT> fftChartData = [];
  List<Complex> inputSignal = <Complex>[];
  List<Complex> outputSignal = <Complex>[];
  List<List<String>> fOutputSignal = <List<String>>[];

  // * List of precision digits for CupertinoPicker
  List<int> precisionList = List<int>.generate(15, (i) => i + 1);

  // Extract data
  @override
  void initState() {
    super.initState();
    // Calculate relevant Fourier transform of input signal
    inputSignal = widget.points;
    outputSignal = fourierTransform(inputSignal, widget.operation);
    fOutputSignal = signalWithFixedPrecision(outputSignal, 3);

    // Pad input signal for FFT (eg: input with 3 signals will produce 4 outputs) to prevent index error
    if (widget.operation == SignalProcessingOperation.opRadix2FFT) {
      final int paddingRequired = outputSignal.length - inputSignal.length;
      Complex complexZero = const Complex(0, 0);
      for (int i = 0; i < paddingRequired; i++) {
        inputSignal.add(complexZero);
      }
    }

    // Create chart data point
    for (var index = 0; index < fOutputSignal[0].length; index++) {
      final ChartFFT o = ChartFFT(
        index,
        double.parse(fOutputSignal[0][index]),
        double.parse(fOutputSignal[1][index]),
      );
      fftChartData.add(o);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        elevation: 1,
        title: Text(widget.appBarTitle),
      ),
      body: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        children: [
          InteractiveChart(fftChartData: fftChartData),
          ListTile(
            leading: const Icon(Icons.swipe_vertical),
            title: const Text("Precision"),
            // titleAlignment: ListTileTitleAlignment.top,
            subtitle: const Text("Set decimal precision"),
            trailing: SizedBox(
              width: MediaQuery.of(context).size.width * 0.34,
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: 2),
                useMagnifier: true,
                magnification: 1.2,
                itemExtent: 32,
                looping: true,
                onSelectedItemChanged: (value) {
                  fOutputSignal = signalWithFixedPrecision(outputSignal, value + 1);
                  setState(() {});
                },
                children: [for (int precision in precisionList) Center(child: Text('$precision'))],
              ),
            ),
          ),
          NumericResults(
            inputSignal: inputSignal,
            fOutputSignal: fOutputSignal,
            transformSymbol: widget.transformSymbol,
          ),
          const SizedBox(height: 64) // Allow some over-scroll
        ],
      ),
    );
  }
}

class InteractiveChart extends StatelessWidget {
  InteractiveChart({super.key, required this.fftChartData});

  final List<ChartFFT> fftChartData;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        // height: MediaQuery.of(context).size.height * 0.50,
        child: SfCartesianChart(
          enableSideBySideSeriesPlacement: false,
          title: ChartTitle(text: 'Graphical Result'),
          primaryXAxis: NumericAxis(
            interval: 1,
            crossesAt: 0,
            majorTickLines: const MajorTickLines(size: 6, width: 2),
          ),
          legend: const Legend(isVisible: true, position: LegendPosition.bottom),
          series: <ChartSeries>[
            ColumnSeries<ChartFFT, int>(
              name: 'Real Part',
              width: 0.05,
              opacity: 0.3,
              dataSource: fftChartData,
              markerSettings: const MarkerSettings(isVisible: true, shape: DataMarkerType.circle),
              xValueMapper: (ChartFFT data, _) => data.time,
              yValueMapper: (ChartFFT data, _) => data.realMag,
            ),
            ColumnSeries<ChartFFT, int>(
              name: 'Imaginary Part',
              width: 0.05,
              opacity: 0.3,
              dataSource: fftChartData,
              markerSettings: const MarkerSettings(isVisible: true, shape: DataMarkerType.diamond),
              xValueMapper: (ChartFFT data, _) => data.time,
              yValueMapper: (ChartFFT data, _) => data.imgMag,
            ),
          ],
        ),
      ),
    );
  }
}

class NumericResults extends StatelessWidget {
  const NumericResults({
    super.key,
    required this.inputSignal,
    required this.fOutputSignal,
    required this.transformSymbol,
  });

  final String transformSymbol;
  final List<Complex> inputSignal;
  final List<List<String>> fOutputSignal;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: fOutputSignal[0].length,
      itemBuilder: (_, index) {
        return NumericResultCard(
          index: index,
          inputSignal: inputSignal,
          transformSymbol: transformSymbol,
          fOutputSignal: fOutputSignal,
        )
            .animate(delay: ((index + 1) * 100).ms)
            .fade(duration: 100.ms)
            .then()
            .shimmer(duration: 200.ms, color: Theme.of(context).colorScheme.tertiaryContainer);
      },
      // Separator
      separatorBuilder: (_, index) {
        return const SizedBox(height: 2);
      },
    );
  }
}

class NumericResultCard extends StatelessWidget {
  const NumericResultCard({
    super.key,
    required this.index,
    required this.inputSignal,
    required this.fOutputSignal,
    required this.transformSymbol,
  });

  final int index;
  final String transformSymbol;
  final List<Complex> inputSignal;
  final List<List<String>> fOutputSignal;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: NumericResultListTile(
        index: index,
        inputSignal: inputSignal,
        fOutputSignal: fOutputSignal,
        transformSymbol: transformSymbol,
      ),
    );
  }
}

class NumericResultListTile extends StatelessWidget {
  const NumericResultListTile({
    super.key,
    required this.index,
    required this.inputSignal,
    required this.fOutputSignal,
    required this.transformSymbol,
  });

  final int index;
  final String transformSymbol;
  final List<Complex> inputSignal;
  final List<List<String>> fOutputSignal;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: SelectableText(
        printDiscretePoint('x', index, inputSignal[index].real.toString(), inputSignal[index].imaginary.toString()),
        style: const TextStyle(fontFamily: "JetBrainsMono", fontSize: 12),
      ),
      subtitle: SelectableText(
        printDiscretePoint(transformSymbol, index, fOutputSignal[0][index], fOutputSignal[1][index]),
        style: const TextStyle(fontFamily: "JetBrainsMono", fontSize: 16),
      ),
    );
  }
}
