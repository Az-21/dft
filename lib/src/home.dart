import 'package:dft/src/functions.dart';
import 'package:dft/src/results.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TextEditingController> img = [TextEditingController()];

  // * Text Controllers
  List<TextEditingController> real = [TextEditingController()];

  /// * Tracker for number of points
  int _numPoints = 1;

  /// * Set inital state to have 0 + i(0)
  @override
  void initState() {
    super.initState();
    real[0].text = '0';
    img[0].text = '0';
  }

  /// * Add a discrete point
  void _addPoint() {
    // Add controllers and set them to '0'
    real.add(TextEditingController());
    img.add(TextEditingController());

    real[_numPoints].text = '0';
    img[_numPoints].text = '0';

    _numPoints++;

    // Update UI
    setState(() {});
  }

  /// * Remove a discrete point (with index <= 1 safety)
  void _removePoint() {
    if (_numPoints > 1) {
      // Remove controllers
      real.removeLast();
      img.removeLast();

      _numPoints--;

      // Update UI
      setState(() {});
    } else {
      Get.snackbar('Info', 'At least one point is required', barBlur: 100, icon: const Icon(Icons.info_outline));
    }
  }

  /// * Goto results page + send data as a list
  void _resultsPage() {
    Get.to(() => const ResultsPage(), arguments: [real, img]);
  }

  /// * UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // * Add and remove FAB
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            elevation: 10,
            onPressed: _addPoint,
            child: const Icon(Icons.post_add_outlined),
          ),
          const SizedBox(
            height: 20,
          ),
          FloatingActionButton(
            onPressed: _removePoint,
            heroTag: null,
            child: const Icon(Icons.delete_forever),
          ),
          const SizedBox(
            height: 20,
          ),
          FloatingActionButton.extended(
            icon: const Icon(Icons.arrow_forward_ios_sharp),
            label: const Text('Evaluate'),
            onPressed: _resultsPage,
            heroTag: null,
          ),
        ],
      ),

      // * Body: Text + 2x TextField
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _numPoints,
        // Widget children
        itemBuilder: (_, index) {
          return Column(
            children: <Widget>[
              // * Print Point
              ListTile(
                title: Text(
                  printDiscretePoint('x', index, real[index].text, img[index].text),
                  style: const TextStyle(fontFamily: 'Inconsolata'),
                ),
                leading: const Icon(Icons.label_important_outline),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    // * Real Part
                    child: TextField(
                      controller: real[index],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Real Part',
                      ),

                      /// * Allow only double input
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'(^\-?\d*\.?\d*)')),
                      ],

                      /// * Update UI
                      onChanged: (value) {
                        setState(() {});
                      },

                      /// * Reset value to '0' if user saves '' or '-'
                      onSubmitted: (value) {
                        if (real[index].text == '' || real[index].text == '-') {
                          real[index].text = '0';
                          setState(() {});
                        }
                      },
                    ),
                  ),

                  const SizedBox(width: 20),

                  // * Img Part
                  Expanded(
                    child: TextField(
                      controller: img[index],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Imaginary Part',
                      ),

                      /// Allow only double
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'(^\-?\d*\.?\d*)')),
                      ],

                      /// * Update UI
                      onChanged: (value) {
                        setState(() {});
                      },

                      /// * Reset value to '0' if user saves '' or '-'
                      onSubmitted: (value) {
                        if (img[index].text == '' || img[index].text == '-') {
                          img[index].text = '0';
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ],
              )
            ],
          );
        },
        // Separator
        separatorBuilder: (_, index) {
          return const SizedBox(height: 20);
        },
      ),
    );
  }
}
