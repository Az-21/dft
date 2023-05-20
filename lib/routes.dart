import 'package:complex/complex.dart';
import 'package:dft/src/about.dart';
import 'package:dft/src/home.dart';
import 'package:dft/src/result/dftResult.dart';
import 'package:dft/src/result/idftResult.dart';
import 'package:dft/src/result/radix2Result.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(routes: [
  GoRoute(path: "/", builder: (context, state) => const HomeScreen(), routes: [
    GoRoute(
      path: "about",
      builder: (context, state) => const AboutPage(),
    ),
    GoRoute(
      path: "FFT",
      builder: (context, state) {
        List<Complex> points = state.extra as List<Complex>;
        return Radix2FFT(points: points);
      },
    ),
    GoRoute(
      path: "DFT",
      builder: (context, state) {
        List<Complex> points = state.extra as List<Complex>;
        return DFT(points: points);
      },
    ),
    GoRoute(
      path: "IDFT",
      builder: (context, state) {
        List<Complex> points = state.extra as List<Complex>;
        return IDFT(points: points);
      },
    ),
  ])
]);
