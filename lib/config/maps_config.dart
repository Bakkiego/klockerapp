/// Google Places is called via the Supabase Edge Function `places-proxy`.
///
/// Set the key as a function secret (do not put it in the Flutter app):
///
/// ```bash
/// supabase secrets set GOOGLE_PLACES_API_KEY=AIza...your_key...
/// supabase functions deploy places-proxy
/// ```
///
/// The client key below is unused for search (kept only as a reminder).
class MapsConfig {
  static const String _unusedClientKey = '';

  @Deprecated('Places calls go through places-proxy; set the key as a Supabase secret.')
  static String get placesApiKey => _unusedClientKey;

  static bool get hasPlacesKey => true;
}
