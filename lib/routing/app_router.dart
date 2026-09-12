import "package:dft/features/about/about_page.dart";
import "package:dft/features/input/input_screen.dart";
import "package:dft/features/results/dft_result.dart";
import "package:dft/features/results/idft_result.dart";
import "package:dft/features/results/radix2_result.dart";
import "package:dft/routing/app_routes.dart";
import "package:dft/routing/route_error_page.dart";
import "package:dft/routing/transform_params.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

/// Builds a transform result screen, or the error page for bad payloads
Widget _transformPage(Object? extra, Widget Function(TransformParams params) build) {
  final params = TransformParams.tryParse(extra);
  if (params == null) return const RouteErrorPage();
  return build(params);
}

/// Application router with lowercase stable paths
final router = GoRouter(
  initialLocation: AppRoutes.home,
  errorBuilder: (context, state) => const RouteErrorPage(),
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(path: "about", builder: (context, state) => const AboutPage()),
        GoRoute(
          path: "fft",
          builder: (context, state) => _transformPage(state.extra, (params) => Radix2FFT(points: params.points)),
        ),
        GoRoute(
          path: "dft",
          builder: (context, state) => _transformPage(state.extra, (params) => DFT(points: params.points)),
        ),
        GoRoute(
          path: "idft",
          builder: (context, state) => _transformPage(state.extra, (params) => IDFT(points: params.points)),
        ),
      ],
    ),
  ],
);
