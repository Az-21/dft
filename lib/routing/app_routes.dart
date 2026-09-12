/// Canonical destination paths for the app
///
/// Route definitions nest the relative names under the home route while
/// navigation uses the full paths below, so pushes work from any location
abstract final class AppRoutes {
  static const home = "/";
  static const about = "/about";
  static const dft = "/dft";
  static const idft = "/idft";
  static const fft = "/fft";
}
