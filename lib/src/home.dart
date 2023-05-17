import 'package:dft/src/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TextEditingController> img = [TextEditingController()];
  List<TextEditingController> real = [TextEditingController()];

  // Tracker for number of points
  int _numPoints = 1;

  // Set initial state to have 0 + i(0)
  @override
  void initState() {
    super.initState();
    real[0].text = '0';
    img[0].text = '0';
  }

  // Add a discrete point
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

  // Remove a discrete point (with index <= 1 safety)
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

  @override
  Widget build(BuildContext context) {
    final m3 = Theme.of(context).colorScheme;
    return Scaffold(
      // Add and remove FAB
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _addPoint,
            elevation: 0,
            backgroundColor: m3.secondaryContainer,
            child: Icon(Icons.add, color: m3.onSecondaryContainer),
          ),
          const SizedBox(height: 20),
          FloatingActionButton(
            onPressed: _removePoint,
            heroTag: null,
            elevation: 0,
            backgroundColor: m3.secondaryContainer,
            child: Icon(Icons.remove, color: m3.onSecondaryContainer),
          ),
          const SizedBox(height: 20),
          FloatingActionButton.extended(
            elevation: 0,
            icon: const Icon(Icons.insights),
            label: const Text('Evaluate'),
            onPressed: () => context.go("/results", extra: [real, img]),
            heroTag: null,
          ),
        ],
      ),

      // Body: Text + 2x TextField
      body: ListView(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: _numPoints,
            itemBuilder: (_, index) {
              return Column(
                children: <Widget>[
                  ListTile(
                    title: Text(
                      printDiscretePoint('x', index, real[index].text, img[index].text),
                      style: const TextStyle(fontFamily: "JetBrainsMono"),
                    ),
                    leading: const Icon(Icons.label_important_outline),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        // Real Part
                        child: TextField(
                          controller: real[index],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Real Part',
                          ),

                          // Allow only double input
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'(^\-?\d*\.?\d*)'))],

                          // Update UI
                          onChanged: (value) => setState(() {}),

                          // Reset value to '0' if user saves '' or '-'
                          onSubmitted: (value) {
                            if (real[index].text == '' || real[index].text == '-') {
                              real[index].text = '0';
                              setState(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextField(
                          controller: img[index],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Imaginary Part',
                          ),

                          // Allow only double
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'(^\-?\d*\.?\d*)')),
                          ],

                          // Update UI
                          onChanged: (value) => setState(() {}),

                          // Reset value to '0' if user saves '' or '-'
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
              ).animate().fadeIn(duration: 300.ms).slideX(duration: 100.ms);
            },
            separatorBuilder: (_, index) => const SizedBox(height: 20),
          ),
          const SizedBox(height: 72),
        ],
      ),
    );
  }
}
