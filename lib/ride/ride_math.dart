class RideMath {
  static double metersToKm(double m) => m / 1000.0;
  static double msToKmh(double ms) => ms * 3.6;

  static double smooth(double prev, double next, {double alpha = 0.2}) {
    return prev + alpha * (next - prev);
  }

  static String formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }
}