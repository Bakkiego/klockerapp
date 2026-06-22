import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Add url_launcher to pubspec.yaml to open the links!

import 'package:klockerapp/supabase/google_calendar_service.dart';

class ZoomMeetingsScreen extends StatefulWidget {
  const ZoomMeetingsScreen({super.key});

  @override
  State<ZoomMeetingsScreen> createState() => _ZoomMeetingsScreenState();
}

class _ZoomMeetingsScreenState extends State<ZoomMeetingsScreen> {
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  bool _isLoading = true;
  List<calendar.Event> _zoomEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchZoomMeetings();
  }

  Future<void> _fetchZoomMeetings() async {
    setState(() => _isLoading = true);
    try {
      // 1. Wake up the connection just in case
      await _calendarService.restoreSession();

      // 2. Fetch all Google Calendar events
      final allEvents = await _calendarService.getUpcomingEvents();

      // 3. 🚀 THE SMART FILTER: Only keep events that are Zoom meetings!
      _zoomEvents = allEvents.where((event) {
        final description = event.description?.toLowerCase() ?? '';
        final location = event.location?.toLowerCase() ?? '';
        final summary = event.summary?.toLowerCase() ?? '';

        return description.contains('zoom.us') ||
            location.contains('zoom.us') ||
            summary.contains('zoom');
      }).toList();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching Zoom events: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper to extract the actual Zoom URL so they can click it
  String? _extractZoomLink(String? text) {
    if (text == null) return null;
    final RegExp zoomRegex = RegExp(
      r'(https:\/\/[a-zA-Z0-9-]+\.zoom\.us\/j\/[^\s]+)',
    );
    final match = zoomRegex.firstMatch(text);
    return match?.group(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Zoom Meetings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchZoomMeetings,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🚀 THE DISCLAIMER BANNER
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blueAccent.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "To schedule, edit, or cancel a meeting, please use the official Zoom app. Changes will automatically sync here.",
                    style: TextStyle(
                      color: isDark ? Colors.blue[200] : Colors.blue[800],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  )
                : _zoomEvents.isEmpty
                ? const Center(
                    child: Text(
                      "No upcoming Zoom meetings found in your calendar.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchZoomMeetings,
                    color: Colors.blueAccent,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _zoomEvents.length,
                      itemBuilder: (context, index) {
                        final event = _zoomEvents[index];

                        // Format Date & Time
                        final startTime = event.start?.dateTime?.toLocal();
                        final dateString = startTime != null
                            ? DateFormat.MMMEd().format(startTime)
                            : "Unknown Date";
                        final timeString = startTime != null
                            ? DateFormat.jm().format(startTime)
                            : "";

                        // Try to find the link in location or description
                        final joinLink =
                            _extractZoomLink(event.location) ??
                            _extractZoomLink(event.description);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const FaIcon(
                                        FontAwesomeIcons.video,
                                        color: Colors.blueAccent,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            event.summary ?? "Zoom Meeting",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "$dateString • $timeString",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (joinLink != null) ...[
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final uri = Uri.parse(joinLink);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(
                                            uri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.link),
                                      label: const Text("Join Meeting"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
