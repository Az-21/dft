import 'package:go_router/go_router.dart';
import 'package:dft/main.dart';
import 'package:dft/src/about.dart';
import 'package:dft/src/results.dart';

final router = GoRouter(routes: [
  GoRoute(path: "/", builder: (context, state) => const Root(), routes: [
    GoRoute(path: "about", builder: (context, state) => const AboutPage()),
    GoRoute(path: "results", builder: (context, state) => const ResultsPage()),
  ])
]);
