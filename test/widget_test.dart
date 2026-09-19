import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weather_app/models/weather.dart';
import 'package:weather_app/services/weather_service.dart';
import 'package:weather_app/utils/units.dart';

void main() {
  test('parses an Open-Meteo forecast response', () async {
    final hours = [
      for (var h = 0; h < 48; h++)
        '2026-09-20T${(h % 24).toString().padLeft(2, '0')}:00'
            .replaceFirst('2026-09-20', h < 24 ? '2026-09-20' : '2026-09-21'),
    ];
    final body = {
      'current': {
        'time': '2026-09-20T10:15',
        'temperature_2m': 24.4,
        'relative_humidity_2m': 40,
        'apparent_temperature': 25.0,
        'is_day': 1,
        'weather_code': 2,
        'wind_speed_10m': 12.0,
        'wind_direction_10m': 270,
        'surface_pressure': 1012.3,
      },
      'hourly': {
        'time': hours,
        'temperature_2m': List.filled(48, 20.0),
        'weather_code': List.filled(48, 0),
        'precipitation_probability': List.filled(48, 10),
        'is_day': List.filled(48, 1),
      },
      'daily': {
        'time': ['2026-09-20'],
        'weather_code': [2],
        'temperature_2m_max': [28.0],
        'temperature_2m_min': [16.0],
        'precipitation_probability_max': [5],
        'uv_index_max': [7.2],
        'sunrise': ['2026-09-20T06:00'],
        'sunset': ['2026-09-20T18:00'],
      },
    };
    final service = WeatherService(
      client: MockClient((_) async => http.Response(jsonEncode(body), 200)),
    );

    final w = await service.fetchWeather(const City(
        name: 'Amman', country: 'Jordan', latitude: 31.9, longitude: 35.9));

    expect(w.temp, 24.4);
    expect(w.hourly.length, 24);
    expect(w.hourly.first.time.hour, 10); // starts at the current hour
    expect(w.today.max, 28.0);
  });

  test('unit conversion', () {
    expect(const Units(fahrenheit: true).temp(0), '32°');
    expect(const Units(fahrenheit: false).temp(21.6), '22°');
    expect(Units.compass(270), 'W');
  });
}
