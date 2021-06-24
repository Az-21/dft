import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:complex/complex.dart';
import 'package:flutter/material.dart';
import 'package:dft/src/functions.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({Key? key}) : super(key: key);

  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  /// * Get data from home page
  // ignore: type_annotate_public_apis
  var data = Get.arguments;

  /// * Extract list of string from the data
  // Init lists
  List<double> real = [];
  List<double> img = [];
  List<Complex> inputSignal = [];
  List<List<String>> result = [];
  // Chart
  late TooltipBehavior _tooltipBehavior;
  late ZoomPanBehavior _zoomPanBehavior;
  List<ChartFFT> fftChartData = [];

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

    /// * Create chart datapoint
    for (var index = 0; index < result[0].length; index++) {
      final ChartFFT o = ChartFFT(
        index,
        double.parse(result[0][index]),
        double.parse(result[1][index]),
      );
      fftChartData.add(o);
    }

    /// * Tooltip + zoom for chart
    _tooltipBehavior = TooltipBehavior(enable: true);
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enableDoubleTapZooming: true,
      enablePanning: true,
    );
  }

  // * List of precision digits for CupertinoPicker
  List<int> precisionList = List<int>.generate(16, (i) => i + 1);

  /// -------------------------------------------------------
  /// * User Interface
  /// -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.back(),
        label: const Text('Back'),
        icon: const Icon(Icons.arrow_back_ios_sharp),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      //
      //
      //
      body: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        children: [
          /// * Precision Picker
          Container(
            color: Colors.green,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Text(
                    'Precision',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                const Icon(Icons.swap_vert_outlined,
                    color: Colors.white, size: 40),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.15,
                  width: MediaQuery.of(context).size.width * 0.40,
                  child: CupertinoPicker(
                    scrollController:
                        FixedExtentScrollController(initialItem: 2),
                    diameterRatio: 1,
                    itemExtent: 40,
                    looping: true,
                    onSelectedItemChanged: (value) {
                      result = resultFFT(inputSignal, value + 1);
                      setState(() {});
                    },
                    children: [
                      for (int precision in precisionList)
                        Center(
                          child: Text('$precision',
                              style: const TextStyle(color: Colors.white)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// * Chart
          Center(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: SfCartesianChart(
                title: ChartTitle(text: 'Graphical Result'),
                primaryXAxis: NumericAxis(
                  majorTickLines: const MajorTickLines(
                    size: 6,
                    width: 2,
                    color: Colors.red,
                  ),
                  minorTickLines: const MinorTickLines(
                    size: 4,
                    width: 2,
                    color: Colors.blue,
                  ),
                  minorTicksPerInterval: 2,
                  crossesAt: 0,
                ),
                tooltipBehavior: _tooltipBehavior,
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                ),
                zoomPanBehavior: _zoomPanBehavior,
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
          ),

          /// * Results
          ListView.separated(
            // rename to ListView.builder if separator isn't required
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: result[0].length, // length of result FFT with padding
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            // Widget children
            itemBuilder: (_, index) {
              return Card(
                elevation: 3,
                child: ListTile(
                  title: ListTile(
                    title: Text(
                      printDiscretePoint('f', index, real[index].toString(),
                          img[index].toString()),
                      style: const TextStyle(
                        fontFamily: 'Inconsolata',
                      ),
                    ),
                    subtitle: Text(
                      printDiscretePoint(
                          'F', index, result[0][index], result[1][index]),
                      style: const TextStyle(
                        fontFamily: 'Inconsolata',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              );
            },
            // Separator
            separatorBuilder: (_, index) {
              return const SizedBox(height: 10);
            },
          ),
        ],
      ),
    );
  }
}
