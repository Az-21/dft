import "package:dft/theme/theme_controller.dart";
import "package:flutter/material.dart";

/// App bar action that cycles the manual theme override
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) {
        return IconButton(
          iconSize: 24,
          tooltip: _tooltipFor(mode),
          onPressed: ThemeController.instance.cycle,
          icon: Icon(_iconFor(mode)),
        );
      },
    );
  }
}

/// Icon reflects the currently active mode
IconData _iconFor(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => Icons.brightness_auto,
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
  };
}

/// Tooltip names the active mode and previews the next one
String _tooltipFor(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => "Theme: system (tap for light)",
    ThemeMode.light => "Theme: light (tap for dark)",
    ThemeMode.dark => "Theme: dark (tap for system)",
  };
}
