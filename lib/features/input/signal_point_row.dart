import "package:dft/core/dsp/fourier_transform.dart";
import "package:dft/features/input/numeric_formatter.dart";
import "package:dft/features/input/signal_input.dart";
import "package:dft/theme/app_theme.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

/// One editable signal point.
///
/// Owns both [TextEditingController]s (created from the draft, disposed with
/// the row) so the screen never juggles parallel controller lists. The row
/// is keyed by draft id, therefore controllers survive parent rebuilds and
/// wholesale replacements such as examples are pushed into the surviving
/// controllers on widget update.
/// Header text updates through a row-local listener: typing never rebuilds
/// the whole list.
class SignalPointRow extends StatefulWidget {
  const SignalPointRow({
    super.key,
    required this.index,
    required this.point,
    required this.isLast,
    required this.realFocus,
    required this.imagFocus,
    required this.onChanged,
    required this.onSubmitReal,
    required this.onSubmitImag,
    required this.onRemove,
    required this.onDuplicate,
  });

  final FocusNode imagFocus;
  final int index;
  final bool isLast;
  final VoidCallback onChanged;
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;
  final VoidCallback onSubmitImag;
  final VoidCallback onSubmitReal;
  final SignalPointInput point;
  final FocusNode realFocus;

  @override
  State<SignalPointRow> createState() => _SignalPointRowState();
}

class _SignalPointRowState extends State<SignalPointRow> {
  late final TextEditingController _imagController = TextEditingController(text: widget.point.imaginary);
  late final TextEditingController _realController = TextEditingController(text: widget.point.real);

  @override
  void initState() {
    super.initState();
    _realController.addListener(_handleTextChanged);
    _imagController.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(SignalPointRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Wholesale draft replacement (examples, restore) arrives with the same
    // key; push the new text into the surviving controllers.
    if (_realController.text != widget.point.real) {
      _realController.text = widget.point.real;
    }
    if (_imagController.text != widget.point.imaginary) {
      _imagController.text = widget.point.imaginary;
    }
  }

  @override
  void dispose() {
    _realController.removeListener(_handleTextChanged);
    _imagController.removeListener(_handleTextChanged);
    _realController.dispose();
    _imagController.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    widget.point.real = _realController.text;
    widget.point.imaginary = _imagController.text;
    widget.onChanged();
    // Refresh the header preview without rebuilding sibling rows.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme m3 = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        ListTile(
          contentPadding: const EdgeInsets.only(left: 12),
          leading: const Icon(Icons.label_important_outline),
          title: Text(
            printDiscretePoint("x", widget.index, _realController.text, _imagController.text),
            style: AppTheme.mono,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                tooltip: "Duplicate point x(${widget.index})",
                iconSize: 22,
                icon: const Icon(Icons.content_copy),
                onPressed: widget.onDuplicate,
              ),
              IconButton(
                tooltip: "Remove point x(${widget.index})",
                iconSize: 25,
                icon: const Icon(Icons.delete_outline),
                onPressed: widget.onRemove,
              ),
            ],
          ),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _realController,
                focusNode: widget.realFocus,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: m3.surface,
                  border: const OutlineInputBorder(),
                  labelText: "Real part of x(${widget.index})",
                ),
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                textInputAction: TextInputAction.next,
                inputFormatters: <TextInputFormatter>[SignedDecimalFormatter()],
                validator: validateNumericText,
                onFieldSubmitted: (_) => widget.onSubmitReal(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _imagController,
                focusNode: widget.imagFocus,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: m3.surface,
                  border: const OutlineInputBorder(),
                  labelText: "Imaginary part of x(${widget.index})",
                ),
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                textInputAction: widget.isLast ? TextInputAction.done : TextInputAction.next,
                inputFormatters: <TextInputFormatter>[SignedDecimalFormatter()],
                validator: validateNumericText,
                onFieldSubmitted: (_) => widget.onSubmitImag(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
