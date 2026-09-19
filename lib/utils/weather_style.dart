import 'package:flutter/material.dart';

/// Visual + textual description of a WMO weather code.
class WeatherStyle {
  const WeatherStyle(this.label, this.icon, this.iconColor);
  final String label;
  final IconData icon;
  final Color iconColor;
}

WeatherStyle styleFor(int code, {bool isDay = true}) {
  switch (code) {
    case 0:
      return isDay
          ? const WeatherStyle('Clear sky', Icons.wb_sunny_rounded, Color(0xFFFFD54F))
          : const WeatherStyle('Clear night', Icons.nightlight_round, Color(0xFFFFF59D));
    case 1:
      return isDay
          ? const WeatherStyle('Mainly clear', Icons.wb_sunny_rounded, Color(0xFFFFD54F))
          : const WeatherStyle('Mainly clear', Icons.nightlight_round, Color(0xFFFFF59D));
    case 2:
      return const WeatherStyle('Partly cloudy', Icons.wb_cloudy_rounded, Color(0xFFFFE082));
    case 3:
      return const WeatherStyle('Overcast', Icons.cloud_rounded, Color(0xFFE3F2FD));
    case 45:
    case 48:
      return const WeatherStyle('Foggy', Icons.foggy, Color(0xFFCFD8DC));
    case 51:
    case 53:
    case 55:
      return const WeatherStyle('Drizzle', Icons.grain_rounded, Color(0xFF80DEEA));
    case 56:
    case 57:
      return const WeatherStyle('Freezing drizzle', Icons.grain_rounded, Color(0xFFB3E5FC));
    case 61:
    case 63:
    case 65:
      return WeatherStyle(code == 65 ? 'Heavy rain' : 'Rain',
          Icons.umbrella_rounded, const Color(0xFF80D8FF));
    case 66:
    case 67:
      return const WeatherStyle('Freezing rain', Icons.umbrella_rounded, Color(0xFFB3E5FC));
    case 71:
    case 73:
    case 75:
    case 77:
      return const WeatherStyle('Snow', Icons.ac_unit_rounded, Color(0xFFE1F5FE));
    case 80:
    case 81:
    case 82:
      return const WeatherStyle('Rain showers', Icons.water_drop_rounded, Color(0xFF80D8FF));
    case 85:
    case 86:
      return const WeatherStyle('Snow showers', Icons.cloudy_snowing, Color(0xFFE1F5FE));
    case 95:
      return const WeatherStyle('Thunderstorm', Icons.thunderstorm_rounded, Color(0xFFFFEA00));
    case 96:
    case 99:
      return const WeatherStyle('Thunderstorm & hail', Icons.thunderstorm_rounded, Color(0xFFFFEA00));
    default:
      return const WeatherStyle('Unknown', Icons.help_outline_rounded, Colors.white);
  }
}

/// Vivid background gradient matching the current conditions.
List<Color> gradientFor(int code, bool isDay) {
  if (!isDay) {
    if (code >= 95) return const [Color(0xFF1A1040), Color(0xFF6A1B9A)];
    if (code >= 51) return const [Color(0xFF1A237E), Color(0xFF3949AB)];
    if (code == 45 || code == 48 || code == 3) {
      return const [Color(0xFF283593), Color(0xFF7986CB)];
    }
    return const [Color(0xFF1A237E), Color(0xFF8E24AA)];
  }
  if (code >= 95) return const [Color(0xFF4A148C), Color(0xFF7C4DFF)];
  if (code >= 71 && code <= 77 || code == 85 || code == 86) {
    return const [Color(0xFF5B86E5), Color(0xFF36D1DC)];
  }
  if (code >= 51) return const [Color(0xFF3A47D5), Color(0xFF00B4DB)];
  if (code == 45 || code == 48) return const [Color(0xFF7F8FA9), Color(0xFF4B5B7A)];
  if (code == 3) return const [Color(0xFF5C7CFA), Color(0xFF3B5BDB)];
  if (code == 2) return const [Color(0xFF2196F3), Color(0xFF7C4DFF)];
  return const [Color(0xFF00B0FF), Color(0xFF7C4DFF)];
}
