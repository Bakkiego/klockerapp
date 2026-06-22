import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';

class GoogleCalendarService {
  // ==========================================
  // 🚀 THE FIX: MAKE THIS A SINGLETON
  // ==========================================
  // 1. Create a private internal constructor
  GoogleCalendarService._internal();

  // 2. Create the single, shared instance
  static final GoogleCalendarService _instance =
      GoogleCalendarService._internal();

  // 3. Whenever a screen asks for this service, give them the shared instance!
  factory GoogleCalendarService() {
    return _instance;
  }
  // ==========================================

  // The Google Sign In object will now stay alive in memory forever!
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '38329521467-9cvvi2miis1ma1a33fsiicu55i9ftmhl.apps.googleusercontent.com',
    scopes: <String>[calendar.CalendarApi.calendarEventsScope],
  );
  // 2. Trigger the Google Login Pop-up

  // 1.5 Check if user is already logged in (for when the web page refreshes)
  Future<bool> restoreSession() async {
    try {
      // signInSilently checks the browser cookies without showing a pop-up
      final account = await _googleSignIn.signInSilently();
      return account != null; // Returns true if it found a saved session!
    } catch (e) {
      debugPrint("Silent Sign-In Error: $e");
      return false;
    }
  }

  Future<GoogleSignInAccount?> connectCalendar() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      debugPrint("Google Sign In Error: $e");
      return null;
    }
  }

  // 3. Fetch the Events
  Future<List<calendar.Event>> getUpcomingEvents() async {
    try {
      // 🚀 Now, _googleSignIn.currentUser will actually be remembered!
      GoogleSignInAccount? account =
          _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();

      if (account == null) {
        throw Exception("User is not connected to Google Calendar");
      }

      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) throw Exception("Failed to authenticate client");

      final calendarApi = calendar.CalendarApi(authClient);

      final events = await calendarApi.events.list(
        'primary',
        timeMin: DateTime.now().toUtc(),
        maxResults: 20,
        singleEvents: true,
        orderBy: 'startTime',
      );

      return events.items ?? [];
    } catch (e) {
      debugPrint("Error fetching calendar events: $e");
      rethrow;
    }
  }

  // 5. Create a New Event (and add employees!)
  Future<calendar.Event?> createEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required List<String> employeeEmails, // The assigned employees!
  }) async {
    try {
      GoogleSignInAccount? account =
          _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      if (account == null) throw Exception("Not signed in");

      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) throw Exception("Failed to authenticate client");

      final calendarApi = calendar.CalendarApi(authClient);

      // 1. Build the Google Event Object
      final newEvent = calendar.Event(
        summary: title,
        description: description,
        start: calendar.EventDateTime(
          dateTime: startTime.toUtc(),
          timeZone: 'UTC', // Google handles the local conversion!
        ),
        end: calendar.EventDateTime(dateTime: endTime.toUtc(), timeZone: 'UTC'),
        // 2. Map your employee emails to Google Attendees
        attendees: employeeEmails
            .map((email) => calendar.EventAttendee(email: email))
            .toList(),
      );

      // 3. Push it to Google Calendar!
      final createdEvent = await calendarApi.events.insert(
        newEvent,
        'primary',
        sendUpdates: 'all',
      );

      return createdEvent;
    } catch (e) {
      debugPrint("Error creating calendar event: $e");
      rethrow;
    }
  }

  // 4. Disconnect
  Future<void> disconnect() async {
    await _googleSignIn.disconnect();
  }
}
