import 'package:complex/complex.dart';
import 'package:dft/src/functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ResultsPageTemplate extends StatefulWidget {
  final String appBarTitle;
  final Uri wikiLink;
  final SignalProcessingOperation operation;
  const ResultsPageTemplate({
    super.key,
    required this.points,
    required this.appBarTitle,
    required this.wikiLink,
    required this.operation,
  });

  final List<List<TextEditingController>> points;

  @override
  State createState() => _ResultsPageTemplateState();
}

class _ResultsPageTemplateState extends State<ResultsPageTemplate> {
  List<Complex> inputSignal = [];
  List<double> img = [];
  List<double> real = [];
  List<List<String>> result = [];
  List<ChartFFT> fftChartData = [];

  // * List of precision digits for CupertinoPicker
  List<int> precisionList = List<int>.generate(16, (i) => i + 1);

  // Extract data
  @override
  void initState() {
    super.initState();
    for (final textController in widget.points[0]) {
      /// * Failsafe to ensure empty data is not parsed
      if (textController.text == '' || textController.text == '-') {
        textController.text = '0';
      }
      real.add(double.parse(textController.text.toString()));
    }
    for (final textController in widget.points[1]) {
      /// * Failsafe to ensure empty data is not parsed
      if (textController.text == '' || textController.text == '-') {
        textController.text = '0';
      }
      img.add(double.parse(textController.text.toString()));
    }

    /// * Convert this data into complex form (real[index] + i*img[index])
    for (var i = 0; i < real.length; i++) {
      inputSignal.add(Complex(real[i], img[i]));
    }

    /// * Calculate fft of input signal
    result = resultFFT(inputSignal, 3, widget.operation);

    /// * Pad the input signal to prevent index error
    final List<double> padding = List.filled(result[0].length - real.length, 0);
    real += padding;
    img += padding;

    /// * Create chart data point
    for (var index = 0; index < result[0].length; index++) {
      final ChartFFT o = ChartFFT(
        index,
        double.parse(result[0][index]),
        double.parse(result[1][index]),
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
      floatingActionButton: FloatingActionButton.extended(
        elevation: 0,
        onPressed: () => context.go("/"),
        label: const Text('Back'),
        icon: const Icon(Icons.arrow_back),
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
                  result = resultFFT(inputSignal, value + 1, widget.operation);
                  setState(() {});
                },
                children: [for (int precision in precisionList) Center(child: Text('$precision'))],
              ),
            ),
          ),
          NumericResults(result: result, real: real, img: img),
          const SizedBox(height: 64) // Allow some over-scroll
        ],
      ),
    );
  }
}

class InteractiveChart extends StatelessWidget {
  InteractiveChart({super.key, required this.fftChartData});

  final List<ChartFFT> fftChartData;

  final _zoomPanBehavior = ZoomPanBehavior(enablePinching: true, enablePanning: true);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        // height: MediaQuery.of(context).size.height * 0.50,
        child: SfCartesianChart(
          title: ChartTitle(text: 'Graphical Result'),
          primaryXAxis: NumericAxis(
            crossesAt: 0,
            minorTicksPerInterval: 2,
            majorTickLines: const MajorTickLines(size: 6, width: 2),
          ),
          zoomPanBehavior: _zoomPanBehavior,
          legend: Legend(isVisible: true, position: LegendPosition.bottom),
          series: <ChartSeries>[
            ColumnSeries<ChartFFT, int>(
              name: 'Real Part',
              width: 0.05,
              opacity: 0.3,
              dataSource: fftChartData,
              markerSettings: const MarkerSettings(isVisible: true),
              xValueMapper: (ChartFFT data, _) => data.time,
              yValueMapper: (ChartFFT data, _) => data.realMag,
            ),
            ColumnSeries<ChartFFT, int>(
              name: 'Imaginary Part',
              width: 0.05,
              opacity: 0.3,
              dataSource: fftChartData,
              markerSettings: const MarkerSettings(isVisible: true),
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
    required this.result,
    required this.real,
    required this.img,
  });

  final List<double> img;
  final List<double> real;
  final List<List<String>> result;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: result[0].length,
      itemBuilder: (_, index) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: ListTile(
            title: ListTile(
              title: SelectableText(
                printDiscretePoint('x', index, real[index].toString(), img[index].toString()),
                style: const TextStyle(fontFamily: "JetBrainsMono", fontSize: 12),
              ),
              subtitle: SelectableText(
                printDiscretePoint('F', index, result[0][index], result[1][index]),
                style: const TextStyle(fontFamily: "JetBrainsMono", fontSize: 16),
              ),
            ),
          ),
        )
            .animate(delay: (index * 100).ms)
            .fade(duration: 200.ms)
            .then()
            .shimmer(duration: 400.ms, color: Theme.of(context).colorScheme.tertiaryContainer);
      },
      // Separator
      separatorBuilder: (_, index) {
        return const SizedBox(height: 2);
      },
    );
  }
}
