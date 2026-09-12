import "package:dft/routing/app_routes.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

/// Fallback for unknown routes and unreadable navigation payloads
class RouteErrorPage extends StatelessWidget {
  const RouteErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Something went wrong")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            const Text("This screen needs a valid signal to display"),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => context.go(AppRoutes.home), child: const Text("Back to input")),
          ],
        ),
      ),
    );
  }
}
