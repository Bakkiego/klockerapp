import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

import 'package:klockerapp/supabase/google_calendar_service.dart';
import 'help-screens/social_settings_screen.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<calendar.Event>> _eventsMap = {};
  List<calendar.Event> _selectedDayEvents = [];

  bool _isLoading = true;
  bool _isCalendarConnected = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchEvents();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _fetchEvents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 🚀 1. THE WAKE-UP CALL
      // Quietly check the browser cookies before trying to fetch data
      bool isConnected = await _calendarService.restoreSession();

      // If the cookie is gone (they actually logged out), stop right here.
      if (!isConnected) {
        if (mounted) {
          setState(() {
            _isCalendarConnected = false;
            _isLoading = false;
          });
        }
        return;
      }

      // 🚀 2. IF WE ARE AWAKE, FETCH THE EVENTS!
      final events = await _calendarService.getUpcomingEvents();

      _eventsMap.clear();
      for (var event in events) {
        final start = event.start?.dateTime ?? event.start?.date;
        if (start != null) {
          final normalized = _normalizeDate(start.toLocal());
          if (_eventsMap[normalized] == null) {
            _eventsMap[normalized] = [];
          }
          _eventsMap[normalized]!.add(event);
        }
      }

      if (mounted) {
        setState(() {
          _isCalendarConnected = true; // Connection restored!
          _selectedDayEvents = _eventsMap[_normalizeDate(_selectedDay!)] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching events for Calendar Screen: $e");
      if (mounted) {
        setState(() {
          _isCalendarConnected = false;
          _isLoading = false;
        });
      }
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedDayEvents = _eventsMap[_normalizeDate(selectedDay)] ?? [];
    });
  }

  // ==========================================
  // 🚀 VIEW EVENT DETAILS BOTTOM SHEET
  // ==========================================
  void _showEventDetails(calendar.Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final startTime = event.start?.dateTime != null
            ? DateFormat.yMMMMEEEEd().add_jm().format(
                event.start!.dateTime!.toLocal(),
              )
            : "All Day";

        final endTime = event.end?.dateTime != null
            ? DateFormat.jm().format(event.end!.dateTime!.toLocal())
            : "";

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.summary ?? "Untitled Event",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (event.description != null &&
                  event.description!.isNotEmpty) ...[
                Text(
                  event.description!,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      endTime.isEmpty ? startTime : "$startTime  -  $endTime",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              const Text(
                "Invited Participants:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (event.attendees == null || event.attendees!.isEmpty)
                const Text(
                  "No participants invited.",
                  style: TextStyle(color: Colors.grey),
                )
              else
                ...event.attendees!.map((attendee) {
                  bool accepted = attendee.responseStatus == "accepted";
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: accepted
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      child: Icon(
                        accepted ? Icons.check : Icons.person,
                        color: accepted ? Colors.green : Colors.grey,
                      ),
                    ),
                    title: Text(attendee.email ?? "Unknown Email"),
                    subtitle: Text(accepted ? "Accepted" : "Pending"),
                  );
                }),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // 🚀 CREATE EVENT WITH MULTIPLE EMAILS & REFRESH
  // ==========================================
  void _showAddEventDialog() {
    final _titleController = TextEditingController();
    final _descController = TextEditingController();
    final _emailController = TextEditingController();

    DateTime _selectedDate =
        _selectedDay ?? DateTime.now(); // Defaults to the day you clicked on!
    TimeOfDay _startTime = TimeOfDay.now();
    TimeOfDay _endTime = TimeOfDay(
      hour: (TimeOfDay.now().hour + 1) % 24,
      minute: TimeOfDay.now().minute,
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Create Event"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: "Event Title",
                      ),
                    ),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: "Description / Notes",
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 🚀 Updated to allow multiple emails
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Invitee Emails",
                        hintText: "email1@app.com, email2@app.com",
                        helperText: "Separate with commas",
                        icon: Icon(Icons.people),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      title: Text(
                        "Date: ${DateFormat.yMMMd().format(_selectedDate)}",
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (date != null)
                          setDialogState(() => _selectedDate = date);
                      },
                    ),
                    ListTile(
                      title: Text("Start: ${_startTime.format(context)}"),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (time != null)
                          setDialogState(() => _startTime = time);
                      },
                    ),
                    ListTile(
                      title: Text("End: ${_endTime.format(context)}"),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (time != null) setDialogState(() => _endTime = time);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final startDateTime = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      _startTime.hour,
                      _startTime.minute,
                    );
                    final endDateTime = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      _endTime.hour,
                      _endTime.minute,
                    );

                    // 🚀 Process comma-separated emails
                    List<String> employees = _emailController.text
                        .split(',')
                        .map((email) => email.trim())
                        .where((email) => email.isNotEmpty)
                        .toList();

                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text("Creating Event...")),
                    );

                    try {
                      await _calendarService.createEvent(
                        title: _titleController.text,
                        description: _descController.text,
                        startTime: startDateTime,
                        endTime: endDateTime,
                        employeeEmails: employees,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text("Event Created Successfully!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }

                      // 🚀 Auto-Refresh the calendar and list!
                      _fetchEvents();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text("Failed: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text("Create"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Company Itinerary',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Events",
            onPressed: _fetchEvents,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _showAddEventDialog,
        icon: const Icon(Icons.add),
        label: const Text("Add Event"),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // THE INTERACTIVE CALENDAR — natural height, no fixed size
                  Container(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    child: TableCalendar(
                      firstDay: DateTime(2024),
                      lastDay: DateTime(2030),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: _onDaySelected,
                      eventLoader: (day) =>
                          _eventsMap[_normalizeDate(day)] ?? [],
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: const Color(0xFF00A36C).withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Color(0xFF00A36C),
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(color: Colors.grey.withOpacity(0.2), thickness: 1),

                  // THE ITINERARY LIST — sizes to its own content now,
                  // since the page around it scrolls instead of forcing
                  // a fixed-height split.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSameDay(_selectedDay, DateTime.now())
                              ? "Today's Itinerary"
                              : DateFormat(
                                  'EEEE, MMMM d',
                                ).format(_selectedDay!),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!_isCalendarConnected)
                          _buildNotConnectedState(isDark)
                        else if (_selectedDayEvents.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                "No events planned for this date.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _selectedDayEvents.length,
                            itemBuilder: (context, index) {
                              final event = _selectedDayEvents[index];
                              final startTime =
                                  event.start?.dateTime ?? event.start?.date;
                              final endTime =
                                  event.end?.dateTime ?? event.end?.date;

                              String timeString = "All Day";
                              if (event.start?.dateTime != null) {
                                final startStr = DateFormat(
                                  'h:mm a',
                                ).format(startTime!.toLocal());
                                final endStr = DateFormat(
                                  'h:mm a',
                                ).format(endTime!.toLocal());
                                timeString = "$startStr - $endStr";
                              }

                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Colors.grey.withOpacity(0.2),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.event_note,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  title: Text(
                                    event.summary ?? "Busy",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      timeString,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                  ),
                                  onTap: () => _showEventDetails(event),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNotConnectedState(bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.red.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 16),
                  SizedBox(width: 6),
                  Text(
                    "Not Connected",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Icon(Icons.sync_disabled, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Sync your Calendar",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              "Connect your Google account to view your daily itinerary.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                if (!_calendarService.isConnected) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SocialSettingsScreen(),
                    ),
                  );
                }

                if (!mounted) return;
                if (!_calendarService.isConnected)
                  return; // they backed out without connecting

                final granted = await _calendarService.requestCalendarAccess();
                if (mounted && granted) {
                  _fetchEvents();
                }
              },
              icon: const Icon(Icons.link),
              label: const Text(
                "Connect Now",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A36C),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
