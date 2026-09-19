import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weather.dart';
import '../utils/units.dart';
import '../utils/weather_style.dart';
import '../weather_controller.dart';
import '../widgets/glass_card.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final WeatherController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WeatherController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_showNotice);
  }

  @override
  void dispose() {
    c.removeListener(_showNotice);
    super.dispose();
  }

  void _showNotice() {
    final msg = c.takeNotice();
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _openSearch(List<Color> colors) async {
    final city = await Navigator.push<City>(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(service: c.service, colors: colors),
      ),
    );
    if (city != null) c.selectCity(city);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final d = c.data;
        final colors = d == null
            ? gradientFor(0, true)
            : gradientFor(d.code, d.isDay);
        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      _TopBar(
                        controller: c,
                        onSearch: () => _openSearch(colors),
                      ),
                      Expanded(child: _body(d)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(WeatherData? d) {
    if (d == null) {
      if (c.error != null) {
        return _ErrorView(message: c.error!, onRetry: c.refresh);
      }
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return RefreshIndicator(
      onRefresh: c.refresh,
      color: Colors.deepPurple,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _Hero(data: d, units: c.units),
          _HourlyCard(data: d, units: c.units),
          _DailyCard(data: d, units: c.units),
          _DetailsGrid(data: d, units: c.units),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Weather data by Open-Meteo.com',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller, required this.onSearch});
  final WeatherController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final city = controller.city;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onSearch,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            city?.name ?? '…',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (city != null && city.subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(city.subtitle,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Search city',
            icon: const Icon(Icons.search_rounded),
            color: Colors.white,
            onPressed: onSearch,
          ),
          IconButton(
            tooltip: 'My location',
            icon: const Icon(Icons.my_location_rounded),
            color: Colors.white,
            onPressed: () => controller.useMyLocation(),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: controller.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh_rounded),
            color: Colors.white,
            onPressed: controller.loading ? null : controller.refresh,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _UnitToggle(
              fahrenheit: controller.fahrenheit,
              onTap: controller.toggleUnit,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.fahrenheit, required this.onTap});
  final bool fahrenheit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget seg(String t, bool active) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(t,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: active ? Colors.deepPurple : Colors.white,
              )),
        );
    return Semantics(
      button: true,
      label: 'Switch temperature unit',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [seg('°C', !fahrenheit), seg('°F', fahrenheit)]),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.data, required this.units});
  final WeatherData data;
  final Units units;

  @override
  Widget build(BuildContext context) {
    final s = styleFor(data.code, isDay: data.isDay);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                s.iconColor.withValues(alpha: 0.35),
                s.iconColor.withValues(alpha: 0.0),
              ]),
            ),
            child: Icon(s.icon, size: 88, color: s.iconColor, shadows: [
              Shadow(color: s.iconColor.withValues(alpha: 0.6), blurRadius: 30),
            ]),
          ),
          Text(
            units.temp(data.temp),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 96,
              fontWeight: FontWeight.w200,
              height: 1.05,
            ),
          ),
          Text(
            s.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'H: ${units.temp(data.today.max)}   L: ${units.temp(data.today.min)}',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, d MMM • h:mm a').format(data.time),
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _HourlyCard extends StatelessWidget {
  const _HourlyCard({required this.data, required this.units});
  final WeatherData data;
  final Units units;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      title: 'Hourly forecast',
      icon: Icons.schedule_rounded,
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
      child: SizedBox(
        height: 116,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: data.hourly.length,
          itemBuilder: (context, i) {
            final h = data.hourly[i];
            final s = styleFor(h.code, isDay: h.isDay);
            return SizedBox(
              width: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(i == 0 ? 'Now' : DateFormat('h a').format(h.time),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w500,
                        fontSize: 13,
                      )),
                  Icon(s.icon, color: s.iconColor, size: 28),
                  SizedBox(
                    height: 14,
                    child: h.precipChance >= 20
                        ? Text('${h.precipChance}%',
                            style: const TextStyle(
                                color: Color(0xFF80D8FF),
                                fontSize: 12,
                                fontWeight: FontWeight.w700))
                        : null,
                  ),
                  Text(units.temp(h.temp),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.data, required this.units});
  final WeatherData data;
  final Units units;

  @override
  Widget build(BuildContext context) {
    final lo = data.daily.map((d) => d.min).reduce(math.min);
    final hi = data.daily.map((d) => d.max).reduce(math.max);
    final span = math.max(hi - lo, 1);
    return GlassCard(
      title: '7-day forecast',
      icon: Icons.calendar_month_rounded,
      child: Column(
        children: [
          for (var i = 0; i < data.daily.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      i == 0 ? 'Today' : DateFormat('EEE').format(data.daily[i].date),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  Icon(styleFor(data.daily[i].code).icon,
                      color: styleFor(data.daily[i].code).iconColor, size: 26),
                  SizedBox(
                    width: 44,
                    child: Text(
                      data.daily[i].precipChance >= 20
                          ? '${data.daily[i].precipChance}%'
                          : '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF80D8FF), fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(units.temp(data.daily[i].min),
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white70, fontSize: 15)),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: _RangeBar(
                        start: (data.daily[i].min - lo) / span,
                        end: (data.daily[i].max - lo) / span,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(units.temp(data.daily[i].max),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({required this.start, required this.end});
  final double start;
  final double end;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final left = w * start;
      final width = math.max(w * (end - start), 8.0);
      return SizedBox(
        height: 6,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Positioned(
              left: math.min(left, w - width),
              width: width,
              top: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF80D8FF), Color(0xFFFFD54F), Color(0xFFFF8A65)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.data, required this.units});
  final WeatherData data;
  final Units units;

  @override
  Widget build(BuildContext context) {
    final t = data.today;
    final tiles = <_Tile>[
      _Tile('Feels like', Icons.thermostat_rounded, units.temp(data.feelsLike), null),
      _Tile('Humidity', Icons.water_drop_rounded, '${data.humidity}%', null),
      _Tile('Wind', Icons.air_rounded, units.wind(data.windSpeed),
          'From ${Units.compass(data.windDirection)}'),
      _Tile('Pressure', Icons.speed_rounded, '${data.pressure.round()} hPa', null),
      _Tile('UV index', Icons.light_mode_rounded, t.uv.round().toString(), Units.uvLabel(t.uv)),
      _Tile('Rain chance', Icons.umbrella_rounded, '${t.precipChance}%', 'Today'),
      _Tile('Sunrise', Icons.wb_twilight_rounded, DateFormat('h:mm a').format(t.sunrise), null),
      _Tile('Sunset', Icons.nights_stay_rounded, DateFormat('h:mm a').format(t.sunset), null),
    ];
    return LayoutBuilder(builder: (context, box) {
      const gap = 14.0;
      final cols = box.maxWidth >= 560 ? 4 : 2;
      final w = (box.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        children: [
          for (final tile in tiles)
            SizedBox(
              width: w,
              child: GlassCard(
                title: tile.title,
                icon: tile.icon,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tile.value,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                    Text(tile.caption ?? ' ',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _Tile {
  const _Tile(this.title, this.icon, this.value, this.caption);
  final String title;
  final IconData icon;
  final String value;
  final String? caption;
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 72, color: Colors.white70),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
