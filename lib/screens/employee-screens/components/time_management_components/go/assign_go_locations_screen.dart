import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:klockerapp/services/place_search_service.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';

/// Pick GO work locations by typing a street address (Uber/Bolt style).
/// Biased to the manager's GPS country/area; selecting saves lat/lng.
class AssignGoLocationsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initiallySelected;

  const AssignGoLocationsScreen({
    super.key,
    this.initiallySelected = const [],
  });

  @override
  State<AssignGoLocationsScreen> createState() =>
      _AssignGoLocationsScreenState();
}

class _AssignGoLocationsScreenState extends State<AssignGoLocationsScreen> {
  final _service = SupabaseService();
  final _places = PlaceSearchService();
  final _search = TextEditingController();
  final _selected = <String, Map<String, dynamic>>{};

  List<PlaceSuggestion> _suggestions = [];
  List<Map<String, dynamic>> _savedLocations = [];
  Position? _near;
  bool _locating = true;
  bool _searching = false;
  bool _savingSelection = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    for (final loc in widget.initiallySelected) {
      final id = loc['id']?.toString();
      if (id != null) _selected[id] = loc;
    }
    _search.addListener(_onSearchChanged);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final position = await _places.resolveUserLocation();
    if (!mounted) return;
    setState(() {
      _near = position;
      _locating = false;
    });
    await _loadSavedLocations();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _search.text.trim();
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _searching = false;
        _error = null;
      });
      return;
    }

    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _runPlaceSearch(query);
    });
  }

  Future<void> _loadSavedLocations() async {
    try {
      final rows = await _service.searchGoLocations('');
      if (!mounted) return;
      setState(() => _savedLocations = rows);
    } catch (_) {
      // Saved catalog is optional; address search still works.
    }
  }

  Future<void> _runPlaceSearch(String query) async {
    try {
      // Refresh GPS if we didn't get it on open (permission prompt, etc.).
      final near = _near ?? await _places.resolveUserLocation();
      if (!mounted) return;
      if (near != null && _near == null) {
        setState(() => _near = near);
      }

      final results = await _places.search(query, near: near);
      if (!mounted || _search.text.trim() != query) return;
      setState(() {
        _suggestions = results;
        _searching = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || _search.text.trim() != query) return;
      setState(() {
        _suggestions = [];
        _searching = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _selectSuggestion(PlaceSuggestion place) async {
    setState(() => _savingSelection = true);
    try {
      // Autocomplete is fast; details call returns lat/lng for the pick.
      final resolved = await _places.resolvePlaceDetails(place);
      final lat = resolved.lat;
      final lng = resolved.lng;
      if (lat == null || lng == null) {
        throw Exception('Could not get coordinates for that address.');
      }

      // Reuse an existing GO location with same coords if one exists.
      Map<String, dynamic>? existing;
      for (final row in _savedLocations) {
        final rowLat = (row['gps_lat'] as num?)?.toDouble();
        final rowLng = (row['gps_long'] as num?)?.toDouble();
        if (rowLat == null || rowLng == null) continue;
        if ((rowLat - lat).abs() < 0.00015 &&
            (rowLng - lng).abs() < 0.00015) {
          existing = row;
          break;
        }
      }

      final saved = existing ??
          await _service.createGoLocation(
            name: resolved.name,
            address: resolved.address,
            lat: lat,
            lng: lng,
          );

      final id = saved['id'].toString();
      if (!mounted) return;
      setState(() {
        _selected[id] = saved;
        if (existing == null) {
          _savedLocations = [..._savedLocations, saved];
        }
        _search.clear();
        _suggestions = [];
        _savingSelection = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingSelection = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save location: $e')),
      );
    }
  }

  void _toggleSaved(Map<String, dynamic> loc) {
    final id = loc['id'].toString();
    setState(() {
      if (_selected.containsKey(id)) {
        _selected.remove(id);
      } else {
        _selected[id] = loc;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim();
    final showSuggestions = query.length >= 2;
    final nearLabel = _locating
        ? 'Getting your location…'
        : (_near != null
            ? 'Searching streets near you'
            : 'Enable GPS for better street results');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign work location'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Work Location (Klocker GO)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      _near != null ? Icons.my_location : Icons.location_off,
                      size: 14,
                      color: _near != null
                          ? const Color(0xFF00A36C)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        nearLabel,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Street name or number, e.g. Main Rd 12',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searching || _savingSelection
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF00A36C),
                              ),
                            ),
                          )
                        : (query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _search.clear();
                                  setState(() {
                                    _suggestions = [];
                                    _error = null;
                                  });
                                },
                              )
                            : null),
                  ),
                ),
                if (_selected.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selected.values.map((loc) {
                      return Chip(
                        avatar: const Icon(Icons.place, size: 16),
                        label: Text(loc['name']?.toString() ?? 'Location'),
                        onDeleted: () {
                          setState(
                            () => _selected.remove(loc['id']?.toString()),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: showSuggestions
                ? _buildSuggestionsList()
                : _buildIdleOrSavedList(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A36C),
                  ),
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.pop(
                            context,
                            _selected.values.toList(),
                          ),
                  child: Text(
                    'Set Location${_selected.length > 1 ? 's (${_selected.length})' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (_searching && _suggestions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00A36C)),
      );
    }

    if (_suggestions.isEmpty) {
      return const Center(
        child: Text(
          'No matching places found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final place = _suggestions[index];
        final icon = place.kind == 'street'
            ? Icons.signpost_outlined
            : (place.kind == 'house'
                ? Icons.home_outlined
                : Icons.place_outlined);
        return ListTile(
          leading: Icon(icon, color: const Color(0xFF00A36C)),
          title: Text(place.name),
          subtitle: Text(
            place.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: _savingSelection ? null : () => _selectSuggestion(place),
        );
      },
    );
  }

  Widget _buildIdleOrSavedList() {
    if (_savedLocations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.signpost_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Search a street address',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _near != null
                    ? 'Start typing a street near you — results are ranked by your location, like Uber or Bolt.'
                    : 'Turn on GPS so we can show streets in your country/area. Then type a street name.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Saved GO locations',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        ..._savedLocations.map((loc) {
          final id = loc['id'].toString();
          final selected = _selected.containsKey(id);
          final address = loc['address']?.toString() ?? '';
          return ListTile(
            leading: Icon(
              selected ? Icons.check_circle : Icons.place_outlined,
              color: selected ? const Color(0xFF00A36C) : Colors.grey,
            ),
            title: Text(loc['name']?.toString() ?? 'Location'),
            subtitle: Text(
              address.isNotEmpty ? address : 'No address',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _toggleSaved(loc),
          );
        }),
      ],
    );
  }
}
