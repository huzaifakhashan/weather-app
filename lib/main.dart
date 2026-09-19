import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'weather_controller.dart';

void main() {
  runApp(const WeatherApp());
}

/// Lets mouse users drag-scroll and pull-to-refresh on web/desktop.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
      };
}

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key, this.controller});

  /// Injectable for tests.
  final WeatherController? controller;

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  late final WeatherController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? WeatherController();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weatherly',
      debugShowCheckedModeBanner: false,
      scrollBehavior: _AppScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF7C4DFF),
        brightness: Brightness.dark,
      ),
      home: HomeScreen(controller: _controller),
    );
  }
}
