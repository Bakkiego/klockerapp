import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

import 'package:klockerapp/supabase/google_calendar_service.dart';
import '../utils/custom_theme/k_calendar_style.dart';
import '../utils/custom_theme/k_palette.dart';
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

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: isError
              ? theme.textTheme.bodyMedium?.copyWith(color: scheme.onError)
              : null,
        ),
        backgroundColor: isError ? scheme.error : null,
      ),
    );
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
        // An all-day event's `date` is already a bare calendar day. Calling
        // toLocal() on it shifts it a day backwards in any negative UTC
        // offset, so only timed events get converted.
        final timed = event.start?.dateTime;
        final start = timed ?? event.start?.date;
        if (start == null) continue;

        final normalized = timed != null
            ? _normalizeDate(start.toLocal())
            : DateTime(start.year, start.month, start.day);

        _eventsMap.putIfAbsent(normalized, () => []).add(event);
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
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final sheetScheme = theme.colorScheme;
        final status = ctx.status;

        final startTime = event.start?.dateTime != null
            ? DateFormat.yMMMMEEEEd().add_jm().format(
                event.start!.dateTime!.toLocal(),
              )
            : "All Day";

        final endTime = event.end?.dateTime != null
            ? DateFormat.jm().format(event.end!.dateTime!.toLocal())
            : "";

        // isScrollControlled only lifts the height cap — without a scroll
        // view an event with a dozen attendees still overflows.
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.summary ?? "Untitled Event",
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                if (event.description != null &&
                    event.description!.isNotEmpty) ...[
                  Text(
                    event.description!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: sheetScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  children: [
                    Icon(Icons.access_time, color: status.pendingFg),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        endTime.isEmpty ? startTime : "$startTime  -  $endTime",
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                Text(
                  "Invited Participants:",
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                if (event.attendees == null || event.attendees!.isEmpty)
                  Text(
                    "No participants invited.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: sheetScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ...event.attendees!.map((attendee) {
                    final bool accepted = attendee.responseStatus == "accepted";
                    final (bg, fg) = status.forStatus(
                      accepted ? 'approved' : 'pending',
                    );

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: bg,
                        child: Icon(
                          accepted ? Icons.check : Icons.person,
                          color: fg,
                        ),
                      ),
                      title: Text(attendee.email ?? "Unknown Email"),
                      subtitle: Text(accepted ? "Accepted" : "Pending"),
                    );
                  }),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Close"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // 🚀 CREATE EVENT WITH MULTIPLE EMAILS & REFRESH
  // ==========================================
  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final emailController = TextEditingController();

    DateTime dialogDate =
        _selectedDay ?? DateTime.now(); // Defaults to the day you clicked on!
    TimeOfDay startTime = TimeOfDay.now();
    // Clamp rather than wrap: at 23:30 the old `(hour + 1) % 24` produced an
    // end time of 00:30, i.e. before the start.
    TimeOfDay endTime = TimeOfDay(
      hour: startTime.hour >= 23 ? 23 : startTime.hour + 1,
      minute: startTime.hour >= 23 ? 59 : startTime.minute,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text("Create Event"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Event Title",
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: "Description / Notes",
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 🚀 Updated to allow multiple emails
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: "Invitee Emails",
                        hintText: "email1@app.com, email2@app.com",
                        helperText: "Separate with commas",
                        prefixIcon: Icon(Icons.people),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      title: Text(
                        "Date: ${DateFormat.yMMMd().format(dialogDate)}",
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: dialogDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setDialogState(() => dialogDate = date);
                        }
                      },
                    ),
                    ListTile(
                      title: Text("Start: ${startTime.format(ctx)}"),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: startTime,
                        );
                        if (time != null) {
                          setDialogState(() => startTime = time);
                        }
                      },
                    ),
                    ListTile(
                      title: Text("End: ${endTime.format(ctx)}"),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: endTime,
                        );
                        if (time != null) {
                          setDialogState(() => endTime = time);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();

                    // Validate BEFORE closing the dialog, so a correction
                    // doesn't mean retyping everything.
                    if (title.isEmpty) {
                      _showSnack("Give the event a title.");
                      return;
                    }

                    final startDateTime = DateTime(
                      dialogDate.year,
                      dialogDate.month,
                      dialogDate.day,
                      startTime.hour,
                      startTime.minute,
                    );
                    final endDateTime = DateTime(
                      dialogDate.year,
                      dialogDate.month,
                      dialogDate.day,
                      endTime.hour,
                      endTime.minute,
                    );

                    if (!endDateTime.isAfter(startDateTime)) {
                      _showSnack("The end time has to be after the start.");
                      return;
                    }

                    // 🚀 Process comma-separated emails
                    final employees = emailController.text
                        .split(',')
                        .map((email) => email.trim())
                        .where((email) => email.isNotEmpty)
                        .toList();

                    Navigator.pop(dialogContext);
                    _createEvent(
                      title: title,
                      description: descController.text.trim(),
                      start: startDateTime,
                      end: endDateTime,
                      emails: employees,
                    );
                  },
                  child: const Text("Create"),
                ),
              ],
            );
          },
        );
      },
      // These three were created fresh on every open and never disposed.
    ).then((_) {
      titleController.dispose();
      descController.dispose();
      emailController.dispose();
    });
  }

  Future<void> _createEvent({
    required String title,
    required String description,
    required DateTime start,
    required DateTime end,
    required List<String> emails,
  }) async {
    _showSnack("Creating Event...");

    try {
      await _calendarService.createEvent(
        title: title,
        description: description,
        startTime: start,
        endTime: end,
        employeeEmails: emails,
      );

      if (!mounted) return;
      _showSnack("Event created.");

      // 🚀 Auto-Refresh the calendar and list!
      _fetchEvents();
    } catch (e) {
      debugPrint("Create event failed: $e");
      _showSnack("Failed: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Itinerary'),
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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // THE INTERACTIVE CALENDAR — natural height, no fixed size
                  Container(
                    color: scheme.surface,
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
                      // Shared with the home screen's calendar.
                      headerStyle: kCalendarHeaderStyle(context),
                      daysOfWeekStyle: kDaysOfWeekStyle(context),
                      calendarStyle: kCalendarStyle(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(thickness: 1),

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
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        if (!_isCalendarConnected)
                          _buildNotConnectedState()
                        else if (_selectedDayEvents.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                "No events planned for this date.",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _selectedDayEvents.length,
                            itemBuilder: (context, index) =>
                                _buildEventCard(_selectedDayEvents[index]),
                          ),
                      ],
                    ),
                  ),
                  // Clears the extended FAB.
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildEventCard(calendar.Event event) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = context.status;

    String timeString = "All Day";
    final start = event.start?.dateTime;
    final end = event.end?.dateTime;
    if (start != null) {
      final startStr = DateFormat('h:mm a').format(start.toLocal());
      // end could be absent on a malformed event — don't force-unwrap it.
      timeString = end != null
          ? "$startStr - ${DateFormat('h:mm a').format(end.toLocal())}"
          : startStr;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: status.pendingBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.event_note, color: status.pendingFg),
        ),
        title: Text(event.summary ?? "Busy", style: theme.textTheme.titleSmall),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            timeString,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        onTap: () => _showEventDetails(event),
      ),
    );
  }

  Widget _buildNotConnectedState() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.error, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: scheme.onErrorContainer,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Not Connected",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Icon(Icons.sync_disabled, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text("Sync your Calendar", style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              "Connect your Google account to view your daily itinerary.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _connectCalendar,
              icon: const Icon(Icons.link),
              label: const Text("Connect Now"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectCalendar() async {
    if (!_calendarService.isConnected) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SocialSettingsScreen()),
      );
    }

    if (!mounted) return;
    // They backed out without connecting.
    if (!_calendarService.isConnected) return;

    final granted = await _calendarService.requestCalendarAccess();
    if (mounted && granted) {
      _fetchEvents();
    }
  }
}
