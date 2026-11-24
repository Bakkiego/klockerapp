import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A street/address suggestion from Google Places Autocomplete.
class PlaceSuggestion {
  final String placeId;
  final String name;
  final String address;
  final double? lat;
  final double? lng;
  final String kind;

  const PlaceSuggestion({
    required this.placeId,
    required this.name,
    required this.address,
    this.lat,
    this.lng,
    this.kind = 'address',
  });

  bool get hasCoordinates => lat != null && lng != null;
}

/// Uber/Bolt-style street search via Google Places.
///
/// Calls Google through the Supabase `places-proxy` Edge Function so it works
/// on Flutter web (Google blocks browser CORS) and keeps the API key off-device.
class PlaceSearchService {
  Position? _cachedPosition;
  String? _cachedCountryCode;
  DateTime? _cachedAt;

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Resolve (and briefly cache) device location for bias + country.
  Future<Position?> resolveUserLocation({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedPosition != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < const Duration(minutes: 5)) {
      return _cachedPosition;
    }

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return _cachedPosition;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _cachedPosition;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      _cachedPosition = position;
      _cachedAt = now;
      _cachedCountryCode ??= await _reverseCountryCode(
        position.latitude,
        position.longitude,
      );
      return position;
    } catch (_) {
      return _cachedPosition;
    }
  }

  String? get countryCode => _cachedCountryCode;

  Future<Map<String, dynamic>> _invoke(
    String action,
    Map<String, dynamic> body,
  ) async {
    final response = await _supabase.functions.invoke(
      'places-proxy',
      body: {'action': action, ...body},
    );

    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Unexpected response from places-proxy');
  }

  Future<List<PlaceSuggestion>> search(
    String query, {
    Position? near,
  }) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final position = near ?? await resolveUserLocation();

    try {
      final body = await _invoke('autocomplete', {
        'input': q,
        if (position != null) 'lat': position.latitude,
        if (position != null) 'lng': position.longitude,
        if (_cachedCountryCode != null) 'country': _cachedCountryCode,
        'radius': 50000,
      });

      final status = body['status']?.toString() ?? '';
      if (status == 'ZERO_RESULTS') return [];
      if (status != 'OK') {
        final msg = body['error_message']?.toString() ?? status;
        throw Exception(msg.isEmpty ? 'Address search failed' : msg);
      }

      final predictions = body['predictions'];
      if (predictions is! List) return [];

      return predictions
          .map((raw) {
            final item = Map<String, dynamic>.from(raw as Map);
            final description = (item['description'] ?? '').toString();
            final structured = item['structured_formatting'] is Map
                ? Map<String, dynamic>.from(
                    item['structured_formatting'] as Map,
                  )
                : <String, dynamic>{};
            final main =
                (structured['main_text'] ?? description.split(',').first)
                    .toString()
                    .trim();
            final secondary =
                (structured['secondary_text'] ??
                        description
                            .replaceFirst(main, '')
                            .replaceFirst(RegExp(r'^,\s*'), ''))
                    .toString()
                    .trim();

            return PlaceSuggestion(
              placeId: (item['place_id'] ?? '').toString(),
              name: main.isEmpty ? description : main,
              address: secondary.isEmpty ? description : secondary,
              kind: 'address',
            );
          })
          .where((s) => s.placeId.isNotEmpty)
          .toList();
    } on FunctionException catch (e) {
      throw Exception(_friendlyFunctionError(e));
    } catch (e) {
      final text = e.toString();
      if (text.contains('Failed to fetch') || text.contains('ClientException')) {
        throw Exception(
          'Could not reach address search. Deploy the places-proxy '
          'Edge Function and set GOOGLE_PLACES_API_KEY on Supabase.',
        );
      }
      rethrow;
    }
  }

  /// Fetch lat/lng for a selected autocomplete prediction.
  Future<PlaceSuggestion> resolvePlaceDetails(
    PlaceSuggestion suggestion,
  ) async {
    if (suggestion.hasCoordinates) return suggestion;

    try {
      final body = await _invoke('details', {
        'place_id': suggestion.placeId,
      });

      if (body['status']?.toString() != 'OK') {
        final msg = body['error_message'] ?? body['status'] ?? 'unknown';
        throw Exception(msg.toString());
      }

      final result = Map<String, dynamic>.from(body['result'] as Map);
      final geometry = result['geometry'] is Map
          ? Map<String, dynamic>.from(result['geometry'] as Map)
          : <String, dynamic>{};
      final location = geometry['location'] is Map
          ? Map<String, dynamic>.from(geometry['location'] as Map)
          : <String, dynamic>{};

      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) {
        throw Exception('Selected place has no coordinates.');
      }

      final formatted = result['formatted_address']?.toString();
      return PlaceSuggestion(
        placeId: suggestion.placeId,
        name: suggestion.name,
        address: (formatted != null && formatted.isNotEmpty)
            ? formatted
            : suggestion.address,
        lat: lat,
        lng: lng,
        kind: suggestion.kind,
      );
    } on FunctionException catch (e) {
      throw Exception(_friendlyFunctionError(e));
    }
  }

  Future<String?> _reverseCountryCode(double lat, double lng) async {
    try {
      final body = await _invoke('reverse_country', {
        'lat': lat,
        'lng': lng,
      });
      if (body['status']?.toString() != 'OK') return null;
      final results = body['results'];
      if (results is! List || results.isEmpty) return null;
      final components = results.first['address_components'];
      if (components is! List) return null;
      for (final raw in components) {
        if (raw is! Map) continue;
        final types = raw['types'];
        if (types is List && types.contains('country')) {
          final code = raw['short_name']?.toString().toLowerCase();
          if (code != null && code.length == 2) return code;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _friendlyFunctionError(FunctionException e) {
    final details = e.details?.toString() ?? '';
    if (details.contains('GOOGLE_PLACES_API_KEY')) {
      return 'Google Places key is not set on the places-proxy function.';
    }
    if (e.status == 404) {
      return 'places-proxy function not deployed yet.';
    }
    return details.isNotEmpty
        ? details
        : 'Address search failed (${e.status})';
  }
}
