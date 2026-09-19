import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather.dart';

class WeatherException implements Exception {
  WeatherException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Talks to the free, key-less Open-Meteo APIs (https://open-meteo.com).
class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw WeatherException('Server error (${res.statusCode}). Try again.');
      }
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } on TimeoutException {
      throw WeatherException('The request timed out. Check your connection.');
    } on WeatherException {
      rethrow;
    } catch (_) {
      throw WeatherException('No internet connection.');
    }
  }

  Future<List<City>> searchCities(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final json = await _getJson(Uri.https(
      'geocoding-api.open-meteo.com',
      '/v1/search',
      {'name': q, 'count': '8', 'language': 'en', 'format': 'json'},
    ));
    final results = (json['results'] as List?) ?? const [];
    return results
        .cast<Map<String, dynamic>>()
        .map(City.fromGeocoding)
        .toList();
  }

  /// Best-effort place name for GPS coordinates. Never throws.
  Future<City> reverseGeocode(double lat, double lon) async {
    try {
      final json = await _getJson(Uri.https(
        'api.bigdatacloud.net',
        '/data/reverse-geocode-client',
        {
          'latitude': '$lat',
          'longitude': '$lon',
          'localityLanguage': 'en',
        },
      ));
      final name = [json['city'], json['locality']]
          .whereType<String>()
          .firstWhere((s) => s.isNotEmpty, orElse: () => 'My location');
      return City(
        name: name,
        country: (json['countryName'] as String?) ?? '',
        region: json['principalSubdivision'] as String?,
        latitude: lat,
        longitude: lon,
      );
    } catch (_) {
      return City(
          name: 'My location', country: '', latitude: lat, longitude: lon);
    }
  }

  Future<WeatherData> fetchWeather(City city) async {
    final j = await _getJson(Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${city.latitude}',
      'longitude': '${city.longitude}',
      'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,'
          'is_day,weather_code,wind_speed_10m,wind_direction_10m,'
          'surface_pressure',
      'hourly': 'temperature_2m,weather_code,precipitation_probability,is_day',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,sunrise,'
          'sunset,uv_index_max,precipitation_probability_max',
      'timezone': 'auto',
      'forecast_days': '7',
    }));

    try {
      final c = j['current'] as Map<String, dynamic>;
      final now = DateTime.parse(c['time'] as String);

      final h = j['hourly'] as Map<String, dynamic>;
      final hTimes = (h['time'] as List).cast<String>();
      final hourly = <HourlyPoint>[];
      for (var i = 0; i < hTimes.length && hourly.length < 24; i++) {
        final t = DateTime.parse(hTimes[i]);
        if (t.isBefore(DateTime(now.year, now.month, now.day, now.hour))) {
          continue;
        }
        hourly.add(HourlyPoint(
          time: t,
          temp: (h['temperature_2m'][i] as num).toDouble(),
          code: (h['weather_code'][i] as num).toInt(),
          precipChance: ((h['precipitation_probability'][i]) as num?)?.toInt() ?? 0,
          isDay: (h['is_day'][i] as num) == 1,
        ));
      }

      final d = j['daily'] as Map<String, dynamic>;
      final dTimes = (d['time'] as List).cast<String>();
      final daily = [
        for (var i = 0; i < dTimes.length; i++)
          DailyPoint(
            date: DateTime.parse(dTimes[i]),
            code: (d['weather_code'][i] as num).toInt(),
            max: (d['temperature_2m_max'][i] as num).toDouble(),
            min: (d['temperature_2m_min'][i] as num).toDouble(),
            precipChance:
                (d['precipitation_probability_max'][i] as num?)?.toInt() ?? 0,
            uv: (d['uv_index_max'][i] as num?)?.toDouble() ?? 0,
            sunrise: DateTime.parse(d['sunrise'][i] as String),
            sunset: DateTime.parse(d['sunset'][i] as String),
          ),
      ];

      return WeatherData(
        time: now,
        temp: (c['temperature_2m'] as num).toDouble(),
        feelsLike: (c['apparent_temperature'] as num).toDouble(),
        humidity: (c['relative_humidity_2m'] as num).toInt(),
        windSpeed: (c['wind_speed_10m'] as num).toDouble(),
        windDirection: (c['wind_direction_10m'] as num).toInt(),
        pressure: (c['surface_pressure'] as num).toDouble(),
        code: (c['weather_code'] as num).toInt(),
        isDay: (c['is_day'] as num) == 1,
        hourly: hourly,
        daily: daily,
      );
    } catch (_) {
      throw WeatherException('Could not read the weather data.');
    }
  }
}
