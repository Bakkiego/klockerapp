import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';

class GoogleCalendarService {
  GoogleCalendarService._internal();
  static final GoogleCalendarService _instance =
      GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '38329521467-9cvvi2miis1ma1a33fsiicu55i9ftmhl.apps.googleusercontent.com',
    scopes: <String>[calendar.CalendarApi.calendarEventsScope],
  );

  bool _hasAttemptedRestore = false;

  /// Identity only — is a Google account signed in at all? Used by the
  /// Settings screen and to gate whether "Connect Now" can proceed.
  bool get isConnected => _googleSignIn.currentUser != null;

  Stream<GoogleSignInAccount?> get onAuthChanged =>
      _googleSignIn.onCurrentUserChanged;

  Future<bool> restoreSession() async {
    if (_hasAttemptedRestore) {
      return isConnected;
    }
    _hasAttemptedRestore = true;
    try {
      final account = await _googleSignIn.signInSilently();
      return account != null;
    } catch (e) {
      debugPrint("Silent Sign-In Error: $e");
      return false;
    }
  }

  /// Identity sign-in ONLY — used by the Settings screen. Does not
  /// request Calendar scope; that's a separate, deliberate step
  /// (see requestCalendarAccess) so it can be triggered by its own
  /// direct button click.
  Future<GoogleSignInAccount?> connectCalendar() async {
    try {
      final account = await _googleSignIn.signIn();
      _hasAttemptedRestore = true;
      return account;
    } catch (e) {
      debugPrint("Google Sign In Error: $e");
      return null;
    }
  }

  /// Requests actual Calendar access. MUST be called directly from a
  /// button's onPressed, with nothing awaited before it in that same
  /// tap — Google requires this to be a direct user gesture, or the
  /// browser silently blocks the consent popup.
  Future<bool> requestCalendarAccess() async {
    try {
      final granted = await _googleSignIn.requestScopes(<String>[
        calendar.CalendarApi.calendarEventsScope,
      ]);
      return granted;
    } catch (e) {
      debugPrint("Calendar scope request error: $e");
      return false;
    }
  }

  Future<List<calendar.Event>> getUpcomingEvents() async {
    try {
      if (!isConnected) {
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

  Future<calendar.Event?> createEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required List<String> employeeEmails,
  }) async {
    try {
      if (!isConnected) throw Exception("Not signed in");

      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) throw Exception("Failed to authenticate client");

      final calendarApi = calendar.CalendarApi(authClient);

      final newEvent = calendar.Event(
        summary: title,
        description: description,
        start: calendar.EventDateTime(
          dateTime: startTime.toUtc(),
          timeZone: 'UTC',
        ),
        end: calendar.EventDateTime(dateTime: endTime.toUtc(), timeZone: 'UTC'),
        attendees: employeeEmails
            .map((email) => calendar.EventAttendee(email: email))
            .toList(),
      );

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

  Future<void> disconnect() async {
    await _googleSignIn.disconnect();
    _hasAttemptedRestore = false;
  }
}
