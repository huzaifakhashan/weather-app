class City {
  const City({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.region,
  });

  final String name;
  final String country;
  final String? region;
  final double latitude;
  final double longitude;

  String get subtitle => [
        if (region != null && region!.isNotEmpty && region != name) region,
        if (country.isNotEmpty) country,
      ].join(', ');

  factory City.fromGeocoding(Map<String, dynamic> j) => City(
        name: j['name'] as String,
        country: (j['country'] as String?) ?? '',
        region: j['admin1'] as String?,
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
      );

  factory City.fromJson(Map<String, dynamic> j) => City(
        name: j['name'] as String,
        country: j['country'] as String,
        region: j['region'] as String?,
        latitude: (j['lat'] as num).toDouble(),
        longitude: (j['lon'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'country': country,
        'region': region,
        'lat': latitude,
        'lon': longitude,
      };
}

class HourlyPoint {
  const HourlyPoint({
    required this.time,
    required this.temp,
    required this.code,
    required this.precipChance,
    required this.isDay,
  });

  final DateTime time;
  final double temp;
  final int code;
  final int precipChance;
  final bool isDay;
}

class DailyPoint {
  const DailyPoint({
    required this.date,
    required this.code,
    required this.max,
    required this.min,
    required this.precipChance,
    required this.uv,
    required this.sunrise,
    required this.sunset,
  });

  final DateTime date;
  final int code;
  final double max;
  final double min;
  final int precipChance;
  final double uv;
  final DateTime sunrise;
  final DateTime sunset;
}

/// All temperatures are in °C and wind speeds in km/h; conversion to the
/// user's preferred unit happens in the UI layer.
class WeatherData {
  const WeatherData({
    required this.time,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.pressure,
    required this.code,
    required this.isDay,
    required this.hourly,
    required this.daily,
  });

  /// Local time at the location (wall-clock components only).
  final DateTime time;
  final double temp;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int windDirection;
  final double pressure;
  final int code;
  final bool isDay;
  final List<HourlyPoint> hourly;
  final List<DailyPoint> daily;

  DailyPoint get today => daily.first;
}
