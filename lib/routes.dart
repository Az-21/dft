import 'package:dft/src/home.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dft/src/about.dart';
import 'package:dft/src/results.dart';

final router = GoRouter(routes: [
  GoRoute(path: "/", builder: (context, state) => const HomeScreen(), routes: [
    GoRoute(
      path: "about",
      builder: (context, state) => const AboutPage(),
    ),
    GoRoute(
      path: "results",
      builder: (context, state) {
        // TODO: Add a class to encapsulate points as Complex instead of a nested list
        List<List<TextEditingController>> points = state.extra as List<List<TextEditingController>>;
        return ResultsPage(points: points);
      },
    ),
  ])
]);