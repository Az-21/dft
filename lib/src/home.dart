import 'package:dft/src/functions.dart';
import 'package:dft/src/results.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TextEditingController> img = [TextEditingController()];
  // * Text Controllers
  List<TextEditingController> real = [TextEditingController()];

  /// * Tracker for number of points
  int _numPoints = 1;

  /// * Set initial state to have 0 + i(0)
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
      final m3 = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: m3.errorContainer,
          content: ListTile(
            leading: Icon(Icons.running_with_errors, color: m3.onErrorContainer),
            title: Text("Illegal Operation", style: TextStyle(color: m3.onErrorContainer)),
            subtitle: Text("At least one point is required", style: TextStyle(color: m3.onErrorContainer)),
          ),
          action: SnackBarAction(label: "Got it", onPressed: () {}, textColor: m3.onErrorContainer),
        ),
      );
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
            onPressed: _addPoint,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: Icon(Icons.add, color: Theme.of(context).colorScheme.onSecondaryContainer),
          ),
          const SizedBox(
            height: 20,
          ),
          FloatingActionButton(
            onPressed: _removePoint,
            heroTag: null,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: Icon(Icons.remove, color: Theme.of(context).colorScheme.onSecondaryContainer),
          ),
          const SizedBox(
            height: 20,
          ),
          FloatingActionButton.extended(
            elevation: 0,
            icon: const Icon(Icons.insights),
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
