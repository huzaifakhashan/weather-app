/// Unit helpers. Data is stored in °C / km/h and converted for display.
class Units {
  const Units({required this.fahrenheit});
  final bool fahrenheit;

  double _t(double c) => fahrenheit ? c * 9 / 5 + 32 : c;

  String temp(double c) => '${_t(c).round()}°';
  String tempWithUnit(double c) => '${_t(c).round()}°${fahrenheit ? 'F' : 'C'}';

  String wind(double kmh) => fahrenheit
      ? '${(kmh * 0.621371).round()} mph'
      : '${kmh.round()} km/h';

  static String compass(int degrees) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[((degrees % 360) / 45).round() % 8];
  }

  static String uvLabel(double uv) {
    if (uv < 3) return 'Low';
    if (uv < 6) return 'Moderate';
    if (uv < 8) return 'High';
    if (uv < 11) return 'Very high';
    return 'Extreme';
  }
}
