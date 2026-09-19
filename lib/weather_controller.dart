import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/weather.dart';
import 'services/location_service.dart';
import 'services/weather_service.dart';
import 'utils/units.dart';

class WeatherController extends ChangeNotifier {
  WeatherController({WeatherService? service, LocationService? location})
      : service = service ?? WeatherService(),
        _location = location ?? LocationService();

  static const _fallbackCity = City(
    name: 'Amman',
    country: 'Jordan',
    latitude: 31.9522,
    longitude: 35.9334,
  );

  final WeatherService service;
  final LocationService _location;
  SharedPreferences? _prefs;

  City? city;
  WeatherData? data;
  bool loading = true;
  String? error;
  bool fahrenheit = false;

  /// One-shot message for the UI to show in a SnackBar.
  String? notice;

  Units get units => Units(fahrenheit: fahrenheit);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    fahrenheit = _prefs?.getBool('fahrenheit') ?? false;

    final saved = _prefs?.getString('city');
    if (saved != null) {
      try {
        await selectCity(City.fromJson(jsonDecode(saved) as Map<String, dynamic>));
        return;
      } catch (_) {/* fall through to GPS */}
    }
    await useMyLocation(silent: true);
  }

  void toggleUnit() {
    fahrenheit = !fahrenheit;
    _prefs?.setBool('fahrenheit', fahrenheit);
    notifyListeners();
  }

  Future<void> selectCity(City c) async {
    city = c;
    _prefs?.setString('city', jsonEncode(c.toJson()));
    await refresh();
  }

  Future<void> useMyLocation({bool silent = false}) async {
    loading = true;
    notifyListeners();
    try {
      final pos = await _location.current();
      await selectCity(await service.reverseGeocode(pos.latitude, pos.longitude));
    } on LocationException catch (e) {
      if (silent) {
        await selectCity(city ?? _fallbackCity);
      } else {
        notice = e.message;
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() async {
    final c = city;
    if (c == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      data = await service.fetchWeather(c);
    } on WeatherException catch (e) {
      if (data == null) {
        error = e.message;
      } else {
        notice = e.message;
      }
    }
    loading = false;
    notifyListeners();
  }

  String? takeNotice() {
    final n = notice;
    notice = null;
    return n;
  }
}
