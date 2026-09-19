import 'dart:async';

import 'package:flutter/material.dart';

import '../models/weather.dart';
import '../services/weather_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.service, required this.colors});

  final WeatherService service;
  final List<Color> colors;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<City> _results = const [];
  bool _loading = false;
  String? _error;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _query = value.trim();
    if (_query.length < 2) {
      setState(() {
        _results = const [];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final q = _query;
      try {
        final r = await widget.service.searchCities(q);
        if (!mounted || q != _query) return;
        setState(() {
          _results = r;
          _error = null;
          _loading = false;
        });
      } on WeatherException catch (e) {
        if (!mounted || q != _query) return;
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.colors,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: Colors.white,
                          tooltip: 'Back',
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            onChanged: _onChanged,
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                            cursorColor: Colors.white,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search city…',
                              hintStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.2),
                              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_loading) const LinearProgressIndicator(minHeight: 2),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) return _hint(Icons.wifi_off_rounded, _error!);
    if (_query.length < 2) {
      return _hint(Icons.travel_explore_rounded, 'Type a city name to find its weather');
    }
    if (_results.isEmpty && !_loading) {
      return _hint(Icons.search_off_rounded, 'No cities found for "$_query"');
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final c = _results[i];
        return ListTile(
          leading: const Icon(Icons.location_city_rounded, color: Colors.white70),
          title: Text(c.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(c.subtitle, style: const TextStyle(color: Colors.white70)),
          onTap: () => Navigator.pop(context, c),
        );
      },
    );
  }

  Widget _hint(IconData icon, String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: Colors.white54),
              const SizedBox(height: 12),
              Text(text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
        ),
      );
}
