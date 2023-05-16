import 'package:complex/complex.dart';
import 'package:dft/src/functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  /// * Get data from home page
  var data = Get.arguments;

  List<ChartFFT> fftChartData = [];
  List<double> img = [];
  List<Complex> inputSignal = [];
  // * List of precision digits for CupertinoPicker
  List<int> precisionList = List<int>.generate(16, (i) => i + 1);

  /// * Extract list of string from the data
  List<double> real = [];
  List<List<String>> result = [];

  // Extract data
  @override
  void initState() {
    super.initState();
    for (final textController in data[0]) {
      /// * Failsafe to ensure empty data is not parsed
      if (textController.text == '' || textController.text == '-') {
        textController.text = '0';
      }
      real.add(double.parse(textController.text.toString()));
    }
    for (final textController in data[1]) {
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
    result = resultFFT(inputSignal, 3);

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

    /// * Tooltip + zoom for chart
  }

  /// -------------------------------------------------------
  /// * User Interface
  /// -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        elevation: 0,
        onPressed: () => Get.back(),
        label: const Text('Back'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        children: [
          /// * Precision Picker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text('Precision', style: TextStyle(fontSize: 24)),
              ),
              const Icon(
                Icons.swap_vert_outlined,
                size: 40,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.15,
                width: MediaQuery.of(context).size.width * 0.40,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: 2),
                  itemExtent: 40,
                  looping: true,
                  onSelectedItemChanged: (value) {
                    result = resultFFT(inputSignal, value + 1);
                    setState(() {});
                  },
                  children: [for (int precision in precisionList) Center(child: Text('$precision'))],
                ),
              ),
            ],
          ),

          InteractiveChart(fftChartData: fftChartData),
          Results(result: result, real: real, img: img),
          const SizedBox(height: 64) // Allow some over-scroll
        ],
      ),
    );
  }
}

class InteractiveChart extends StatelessWidget {
  final List<ChartFFT> fftChartData;
  final _tooltipBehavior = TooltipBehavior(enable: true);
  final _zoomPanBehavior = ZoomPanBehavior(enablePinching: true, enablePanning: true);
  InteractiveChart({super.key, required this.fftChartData});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        // height: MediaQuery.of(context).size.height * 0.50,
        child: SfCartesianChart(
          title: ChartTitle(text: 'Graphical Result'),
          primaryXAxis: NumericAxis(
            majorTickLines: const MajorTickLines(size: 6, width: 2, color: Colors.red),
            minorTickLines: const MinorTickLines(size: 4, width: 2, color: Colors.blue),
            minorTicksPerInterval: 2,
            crossesAt: 0,
          ),
          tooltipBehavior: _tooltipBehavior,
          zoomPanBehavior: _zoomPanBehavior,
          legend: Legend(isVisible: true, position: LegendPosition.bottom),
          series: <ChartSeries>[
            LineSeries<ChartFFT, int>(
              name: 'Real Part',
              dataSource: fftChartData,
              markerSettings: const MarkerSettings(isVisible: true),
              xValueMapper: (ChartFFT data, _) => data.time,
              yValueMapper: (ChartFFT data, _) => data.realMag,
            ),
            LineSeries<ChartFFT, int>(
              name: 'Imaginary Part',
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

class Results extends StatelessWidget {
  const Results({
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
              title: Text(
                printDiscretePoint('x', index, real[index].toString(), img[index].toString()),
                style: const TextStyle(fontFamily: 'Inconsolata'),
              ),
              subtitle: Text(
                printDiscretePoint('F', index, result[0][index], result[1][index]),
                style: const TextStyle(fontFamily: 'Inconsolata', fontSize: 16, fontWeight: FontWeight.w900),
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
