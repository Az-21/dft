import 'package:dft/src/functions.dart';
import 'package:easy_dynamic_theme/easy_dynamic_theme.dart';
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
            title: Text("At least one point is required", style: TextStyle(color: m3.onErrorContainer)),
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
      bottomNavigationBar: BottomAppBar(
        elevation: 1,
        child: Wrap(
          spacing: 8,
          children: [
            FilledButton.tonal(
              onPressed: () {
                _fixMissingTextFields(real, img);
                context.go("/IDFT", extra: [real, img]);
              },
              child: const Text("IDFT"),
            ),
            FilledButton.tonal(
              onPressed: () {
                _fixMissingTextFields(real, img);
                context.go("/DFT", extra: [real, img]);
              },
              child: const Text("DFT"),
            ),
            FilledButton.tonal(
              onPressed: () {
                _fixMissingTextFields(real, img);
                context.go("/Radix2FFT", extra: [real, img]);
              },
              child: const Text("FFT"),
            ),
          ],
        ),
      ),

      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        toolbarHeight: 100,
        elevation: 1,
        title: const Text("iDFT Calculator"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.go("/about"),
            iconSize: 24,
          ),
          EasyDynamicThemeSwitch(),
        ],
      ),
      // Add and remove FAB
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      floatingActionButton: Wrap(
        spacing: 8,
        children: [
          FloatingActionButton(
            onPressed: _addPoint,
            elevation: 0,
            backgroundColor: m3.primaryContainer,
            child: Icon(Icons.add, color: m3.onPrimaryContainer),
          ),
          FloatingActionButton(
            onPressed: _removePoint,
            heroTag: null,
            elevation: 0,
            backgroundColor: m3.tertiaryContainer,
            child: Icon(Icons.remove, color: m3.onTertiaryContainer),
          ),
        ],
      ),

      // Body: Text + 2x TextField
      body: ListView.separated(
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
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'(^\-?\d*\.?\d*)'))],
                      onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) => real[index].clear()),
                      onSubmitted: (value) {
                        _fixMissingTextField(real[index]);
                        img[index].clear();
                        setState(() {});
                      },
                      onTapOutside: (value) {
                        _fixMissingTextField(real[index]);
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: m3.background,
                        border: const OutlineInputBorder(),
                        labelText: 'Real Part',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: img[index],
                      textInputAction: TextInputAction.next,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'(^\-?\d*\.?\d*)'))],
                      onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) => img[index].clear()),
                      onSubmitted: (value) {
                        _fixMissingTextField(img[index]);
                        // Ensure index++ element actually exists
                        if (index + 1 != _numPoints) {
                          real[index + 1].clear();
                        }
                        setState(() {});
                      },
                      onTapOutside: (value) {
                        _fixMissingTextField(img[index]);
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: m3.background,
                        border: const OutlineInputBorder(),
                        labelText: 'Imaginary Part',
                      ),
                    ),
                  ),
                ],
              )
            ],
          ).animate().fadeIn(duration: 100.ms).then().shimmer(duration: 200.ms, color: m3.secondaryContainer);
        },
        separatorBuilder: (_, index) => const SizedBox(height: 20),
      ),
    );
  }
}

/// WARN: function with side-effect
_fixMissingTextFields(List<TextEditingController> re, List<TextEditingController> im) {
  final N = re.length;

  for (int i = 0; i < N; i++) {
    _fixMissingTextField(re[i]);
    _fixMissingTextField(im[i]);
  }
}

/// WARN: Function with side-effect
_fixMissingTextField(TextEditingController textfield) {
  if (textfield.text == '' || textfield.text == '-' || textfield.text == '.') {
    textfield.text = '0';
  }
}
