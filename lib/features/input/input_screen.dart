import "package:dft/core/dsp/fourier_transform.dart";
import "package:dft/features/input/signal_input.dart";
import "package:dft/features/input/signal_point_row.dart";
import "package:dft/routing/app_routes.dart";
import "package:dft/routing/transform_params.dart";
import "package:dft/theme/app_theme.dart";
import "package:dft/theme/theme_mode_button.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:go_router/go_router.dart";

/// Runtime state for one editable point: the string draft plus its focus
/// nodes. A single list of these replaces the old parallel controller lists,
/// so rows can never drift out of sync. Controllers live inside
/// [SignalPointRow] and are keyed by [SignalPointInput.id].
class _PointState {
  _PointState(this.draft, VoidCallback onFocusChange)
    : realFocus = FocusNode(),
      imagFocus = FocusNode(),
      _onFocusChange = onFocusChange {
    realFocus.addListener(_onFocusChange);
    imagFocus.addListener(_onFocusChange);
  }

  final SignalPointInput draft;
  final FocusNode imagFocus;
  final FocusNode realFocus;
  final VoidCallback _onFocusChange;

  void dispose() {
    realFocus.removeListener(_onFocusChange);
    imagFocus.removeListener(_onFocusChange);
    realFocus.dispose();
    imagFocus.dispose();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RestorationMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final RestorableString _payload = RestorableString("");
  final ScrollController _scrollController = ScrollController();

  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<_PointState> _points;
  int _nextId = 1;

  @override
  String? get restorationId => "home_screen";

  @override
  void initState() {
    super.initState();
    _points = <_PointState>[_PointState(SignalPointInput(id: 0), _handleFocusChange)];
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_payload, "points_payload");
    if (initialRestore && _payload.value.isNotEmpty) {
      final ({List<SignalPointInput> points, int nextId})? restored = decodeSignalInputs(_payload.value);
      if (restored != null) {
        for (final _PointState point in _points) {
          point.dispose();
        }
        _points = <_PointState>[
          for (final SignalPointInput draft in restored.points) _PointState(draft, _handleFocusChange),
        ];
        _nextId = restored.nextId;
      }
    }
  }

  @override
  void dispose() {
    for (final _PointState point in _points) {
      point.dispose();
    }
    _scrollController.dispose();
    _payload.dispose();
    super.dispose();
  }

  List<SignalPointInput> get _drafts => <SignalPointInput>[for (final _PointState point in _points) point.draft];

  /// Flat keyboard traversal order: real, imaginary, row by row.
  List<FocusNode> get _focusOrder => <FocusNode>[
    for (final _PointState point in _points) ...<FocusNode>[point.realFocus, point.imagFocus],
  ];

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _syncPayload() {
    _payload.value = encodeSignalInputs(_drafts, _nextId);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Shimmer sweep played once when a transitioning row first builds, so
  /// existing rows do not replay it on parent rebuilds.
  Widget _withShimmer(Widget child) {
    final Color shimmerColor = Theme.of(context).colorScheme.tertiaryContainer;
    return child.animate().shimmer(duration: 400.ms, color: shimmerColor);
  }

  /// Addition: the new row slides in from the left with a shimmer sweep.
  Widget _animateInsertion(Widget child, Animation<double> animation) {
    final CurvedAnimation curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    return SlideTransition(
      position: Tween(begin: const Offset(-1, 0), end: Offset.zero).animate(curved),
      child: _withShimmer(child),
    );
  }

  /// Deletion: the row slides out to the right with no shimmer.
  /// The outgoing animation runs from 1 down to 0, so the slide is driven by
  /// a [ReverseAnimation] to travel outward as the value falls.
  Widget _animateRemoval(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween(begin: Offset.zero, end: const Offset(1, 0)).animate(
        CurvedAnimation(parent: ReverseAnimation(animation), curve: Curves.easeIn),
      ),
      child: child,
    );
  }

  /// Static preview shown for a row while it animates out. It only reads the
  /// removed draft strings, so the live controllers may already be disposed.
  Widget _buildDepartingRow(SignalPointInput draft, int index, Animation<double> animation) {
    return _animateRemoval(
      ListTile(
        leading: const Icon(Icons.label_important_outline),
        title: Text(printDiscretePoint("x", index, draft.real, draft.imaginary), style: AppTheme.mono),
      ),
      animation,
    );
  }

  void _addPoint() {
    if (_points.length >= maxInputPoints) {
      _showMessage("Maximum of $maxInputPoints points reached - DFT cost grows quadratically.");
      return;
    }
    setState(() {
      _points.add(_PointState(SignalPointInput(id: _nextId++), _handleFocusChange));
      _syncPayload();
    });
    _listKey.currentState?.insertItem(_points.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeLast() {
    _removeAt(_points.length - 1);
  }

  void _removeAt(int index) {
    if (_points.length <= 1) {
      _showMessage("At least one point is required");
      return;
    }
    final _PointState removed = _points[index];
    _listKey.currentState?.removeItem(
      index,
      (BuildContext context, Animation<double> animation) => _buildDepartingRow(removed.draft, index, animation),
    );
    setState(() {
      _points.removeAt(index).dispose();
      _syncPayload();
    });
  }

  void _duplicateAt(int index) {
    if (_points.length >= maxInputPoints) {
      _showMessage("Maximum of $maxInputPoints points reached - DFT cost grows quadratically.");
      return;
    }
    final SignalPointInput source = _points[index].draft;
    setState(() {
      _points.insert(
        index + 1,
        _PointState(
          SignalPointInput(id: _nextId++, real: source.real, imaginary: source.imaginary),
          _handleFocusChange,
        ),
      );
      _syncPayload();
    });
    _listKey.currentState?.insertItem(index + 1);
  }

  Future<void> _clearAll() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Clear all points?"),
          content: Text("This removes all ${_points.length} points and resets to a single zero point."),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text("Cancel")),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text("Clear")),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      for (final _PointState point in _points) {
        point.dispose();
      }
      _points = <_PointState>[_PointState(SignalPointInput(id: _nextId++), _handleFocusChange)];
      // Wholesale replacement: swap in a fresh list instead of animating.
      _listKey = GlobalKey<AnimatedListState>();
      _syncPayload();
    });
  }

  void _loadExample(String kind) {
    final List<SignalPoint> example = exampleSignal(kind);
    setState(() {
      for (final _PointState point in _points) {
        point.dispose();
      }
      _points = <_PointState>[
        for (final SignalPoint sample in example)
          _PointState(
            SignalPointInput(
              id: _nextId++,
              real: exampleFieldText(sample.real),
              imaginary: exampleFieldText(sample.imaginary),
            ),
            _handleFocusChange,
          ),
      ];
      // Wholesale replacement: swap in a fresh list instead of animating.
      _listKey = GlobalKey<AnimatedListState>();
      _syncPayload();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  /// Builds the editable row for [index], spaced from the next row.
  Widget _buildRow(int index) {
    final _PointState point = _points[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SignalPointRow(
        key: ValueKey<int>(point.draft.id),
        index: index,
        point: point.draft,
        isLast: index == _points.length - 1,
        realFocus: point.realFocus,
        imagFocus: point.imagFocus,
        onChanged: _syncPayload,
        onSubmitReal: () => _requestField(point.imagFocus),
        onSubmitImag: () => _focusFrom(point.imagFocus),
        onRemove: () => _removeAt(index),
        onDuplicate: () => _duplicateAt(index),
      ),
    );
  }

  void _requestField(FocusNode node) {
    node.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? fieldContext = node.context;
      if (fieldContext != null && mounted) {
        Scrollable.ensureVisible(fieldContext, alignment: 0.4, duration: const Duration(milliseconds: 250));
      }
    });
  }

  void _focusFrom(FocusNode current) {
    final List<FocusNode> order = _focusOrder;
    final int index = order.indexOf(current);
    if (index != -1 && index + 1 < order.length) {
      _requestField(order[index + 1]);
    } else {
      current.unfocus();
    }
  }

  void _submit(String route) {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      _showMessage("Some fields need attention - enter valid numbers.");
      return;
    }
    final ParsedSignalInput parsed = parseSignalInputs(_drafts);
    if (!parsed.isValid) {
      _showMessage(parsed.errors.first.toString());
      return;
    }
    context.push(route, extra: TransformParams(parsed.points));
  }

  /// Accessory bar above the keyboard: Next steps through fields in order,
  /// Done confirms editing and dismisses the keyboard.
  Widget _buildKeyboardToolbar() {
    final bool keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final List<FocusNode> order = _focusOrder;
    final int current = order.indexWhere((FocusNode node) => node.hasFocus);
    if (!keyboardOpen || current == -1) {
      return const SizedBox.shrink();
    }
    return Material(
      elevation: 4,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: <Widget>[
              Tooltip(
                message: "Previous field",
                child: TextButton.icon(
                  onPressed: current > 0 ? () => _requestField(order[current - 1]) : null,
                  icon: const Icon(Icons.north_west),
                  label: const Text("Previous"),
                ),
              ),
              Tooltip(
                message: "Next field",
                child: TextButton.icon(
                  onPressed: current + 1 < order.length ? () => _requestField(order[current + 1]) : null,
                  icon: const Icon(Icons.south_east),
                  label: const Text("Next"),
                ),
              ),
              const Spacer(),
              Tooltip(
                message: "Confirm and dismiss keyboard",
                child: FilledButton.tonalIcon(
                  onPressed: () => order[current].unfocus(),
                  icon: const Icon(Icons.check),
                  label: const Text("Done"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme m3 = Theme.of(context).colorScheme;
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        elevation: 1,
        child: Wrap(
          spacing: 8,
          children: <Widget>[
            FilledButton.tonal(onPressed: () => _submit(AppRoutes.idft), child: const Text("IDFT")),
            FilledButton.tonal(onPressed: () => _submit(AppRoutes.dft), child: const Text("DFT")),
            FilledButton.tonal(onPressed: () => _submit(AppRoutes.fft), child: const Text("FFT")),
          ],
        ),
      ),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        toolbarHeight: 100,
        elevation: 1,
        title: const Text("DFT Calculator"),
        actions: <Widget>[
          PopupMenuButton<String>(
            tooltip: "Input actions",
            icon: const Icon(Icons.more_vert),
            onSelected: (String action) {
              if (action == "clear") {
                _clearAll();
              } else {
                _loadExample(action);
              }
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: "impulse", child: Text("Load impulse example")),
                const PopupMenuItem<String>(value: "step", child: Text("Load step example")),
                const PopupMenuItem<String>(value: "cosine", child: Text("Load cosine example")),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(value: "clear", child: Text("Clear all points")),
              ];
            },
          ),
          IconButton(
            tooltip: "About",
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.push(AppRoutes.about),
            iconSize: 24,
          ),
          const ThemeModeButton(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      floatingActionButton: Wrap(
        spacing: 8,
        children: <Widget>[
          FloatingActionButton(
            tooltip: "Add point",
            onPressed: _addPoint,
            elevation: 0,
            backgroundColor: m3.primaryContainer,
            child: Icon(Icons.add, color: m3.onPrimaryContainer),
          ),
          FloatingActionButton(
            tooltip: "Remove last point",
            onPressed: _removeLast,
            heroTag: null,
            elevation: 0,
            backgroundColor: m3.tertiaryContainer,
            child: Icon(Icons.remove, color: m3.onTertiaryContainer),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            Expanded(
              child: AnimatedList(
                key: _listKey,
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                initialItemCount: _points.length,
                itemBuilder: (BuildContext context, int index, Animation<double> animation) {
                  return _animateInsertion(_buildRow(index), animation);
                },
              ),
            ),
            _buildKeyboardToolbar(),
          ],
        ),
      ),
    );
  }
}
