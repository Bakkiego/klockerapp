import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:klockerapp/components/notifications_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:table_calendar/table_calendar.dart';
import 'package:klockerapp/providers/user_provider.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:klockerapp/supabase/google_calendar_service.dart';
import 'package:klockerapp/utils/custom_theme/k_palette.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/attendance_summary.dart';
import 'package:klockerapp/screens/floating_clock_button.dart';
import 'package:klockerapp/screens/profile_settings_screen.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  static String id = 'home_screen';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

  final GoogleCalendarService _calendarService = GoogleCalendarService();
  StreamSubscription<GoogleSignInAccount?>? _authSub;
  List<calendar.Event> _googleEvents = [];
  bool _isCalendarConnected = false;
  bool _isLoadingCalendar = true;

  String _tenantName = "Loading Workspace...";
  List<Map<String, dynamic>> _selectedDateRecords = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _initGoogleCalendar();
    _authSub = _calendarService.onAuthChanged.listen((account) {
      if (mounted && account != null && !_isCalendarConnected) {
        setState(() => _isCalendarConnected = true);
        _checkGoogleCalendarConnection();
      }
    });
  }

  @override
  void dispose() {
    // This was leaking — the subscription was created but never cancelled.
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _initGoogleCalendar() async {
    final connected = await _calendarService.restoreSession();
    if (!mounted) return;
    setState(() => _isCalendarConnected = connected);
    if (connected) {
      await _checkGoogleCalendarConnection();
    } else {
      setState(() => _isLoadingCalendar = false);
    }
  }

  // ==========================================
  // --- GOOGLE CALENDAR LOGIC ---
  // ==========================================
  Map<DateTime, List<dynamic>> _calendarMarkers = {};

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _handleConnectNowPressed() async {
    if (!_calendarService.isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please connect your Google account in Settings first.",
            ),
          ),
        );
      }
      return;
    }

    final granted = await _calendarService.requestCalendarAccess();
    if (!mounted) return;

    if (granted) {
      await _checkGoogleCalendarConnection();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Calendar access wasn't granted. Please try again."),
        ),
      );
    }
  }

  Future<void> _checkGoogleCalendarConnection() async {
    setState(() => _isLoadingCalendar = true);
    try {
      final events = await _calendarService.getUpcomingEvents();

      _calendarMarkers.clear();
      for (var event in events) {
        final start = event.start?.dateTime ?? event.start?.date;
        if (start != null) {
          final normalized = _normalizeDate(start.toLocal());
          if (_calendarMarkers[normalized] == null) {
            _calendarMarkers[normalized] = [];
          }
          _calendarMarkers[normalized]!.add(event);
        }
      }

      if (mounted) {
        setState(() {
          _googleEvents = events;
          _isCalendarConnected = true;
          _isLoadingCalendar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalendarConnected = false;
          _isLoadingCalendar = false;
        });
      }
    }
  }

  // ==========================================
  // --- KLOCKERAPP DATA FETCHING ---
  // ==========================================
  Future<void> _fetchInitialData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase
          .from('profiles')
          .select('*, tenants(name)')
          .eq('id', user.id)
          .single();

      if (mounted) {
        if (data['full_name'] != null) {
          context.read<UserProvider>().setFullName(data['full_name']);
        }
        if (data['avatar_url'] != null) {
          context.read<UserProvider>().setAvatarUrl(data['avatar_url']);
        }

        setState(() {
          _tenantName = data['tenants']?['name'] ?? 'Company Workspace';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _tenantName = 'Company Workspace');
    }

    try {
      final attendanceData = await SupabaseService().getCompanyAttendanceByDate(
        _selectedDate,
      );
      if (mounted) {
        setState(() {
          _selectedDateRecords = attendanceData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAttendanceForDate(DateTime date) async {
    setState(() => _isLoading = true);
    try {
      final attendanceData = await SupabaseService().getCompanyAttendanceByDate(
        date,
      );
      if (mounted) {
        setState(() {
          _selectedDate = date;
          _selectedDateRecords = attendanceData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning, $name";
    if (hour < 17) return "Good Afternoon, $name";
    return "Good Evening, $name"; // was "Good Evenings"
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final userProvider = context.watch<UserProvider>();
    final fullName = userProvider.fullName ?? 'Manager';
    final firstName = fullName.split(' ').first;
    final avatarUrl = userProvider.avatarUrl;

    final isToday =
        _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      floatingActionButton: const FloatingClockButton(),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 80.0 : 20.0,
            vertical: 32.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER ---
              isWeb
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(firstName),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _tenantName,
                                style: theme.textTheme.displaySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildNotificationBell(context),
                                const SizedBox(width: 16),
                                _buildAvatar(context, avatarUrl),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting(firstName),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _tenantName,
                                    style: theme.textTheme.headlineMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _buildNotificationBell(context),
                                const SizedBox(width: 12),
                                _buildAvatar(context, avatarUrl),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Styling comes from searchBarTheme once added; the
                        // leading icon still needs its colour here.
                        SearchBar(
                          hintText: 'Search features...',
                          leading: Padding(
                            padding: const EdgeInsets.only(
                              left: 12.0,
                              right: 8.0,
                            ),
                            child: Icon(
                              Icons.search,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),

              const SizedBox(height: 60),

              // --- 2. ATTENDANCE SUMMARY ---
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday
                            ? "Today's Attendance Overview"
                            : "Overview for ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : AttendanceSummary(records: _selectedDateRecords),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 50),
              const Divider(),
              const SizedBox(height: 40),

              // --- 3. CALENDAR & SCHEDULE ---
              isWeb
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 550,
                            child: _buildCalendar(context),
                          ),
                        ),
                        Container(
                          height: 550,
                          width: 1,
                          color: scheme.outline,
                          margin: const EdgeInsets.symmetric(horizontal: 50),
                        ),
                        Expanded(
                          flex: 2,
                          child: _buildGoogleCalendarPanel(context),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        SizedBox(height: 400, child: _buildCalendar(context)),
                        const SizedBox(height: 30),
                        const Divider(),
                        const SizedBox(height: 30),
                        _buildGoogleCalendarPanel(context),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  /// The calendar was duplicated verbatim for web and mobile. One copy now.
  Widget _buildCalendar(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return TableCalendar(
      firstDay: DateTime(2024),
      lastDay: DateTime(2030),
      focusedDay: _selectedDate,
      currentDay: DateTime.now(),
      selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(_selectedDate, selectedDay)) {
          _fetchAttendanceForDate(selectedDay);
        }
      },
      eventLoader: (day) => _calendarMarkers[_normalizeDate(day)] ?? [],
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: theme.textTheme.titleMedium ?? const TextStyle(),
        leftChevronIcon: Icon(Icons.chevron_left, color: scheme.onSurface),
        rightChevronIcon: Icon(Icons.chevron_right, color: scheme.onSurface),
      ),
      // TableCalendar is a third-party widget with no theme hook, so it has
      // to be styled explicitly — but from scheme values, not literals.
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: scheme.onSurfaceVariant),
        weekendStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      calendarStyle: CalendarStyle(
        defaultTextStyle: TextStyle(color: scheme.onSurface),
        weekendTextStyle: TextStyle(color: scheme.onSurface),
        outsideTextStyle: TextStyle(
          color: scheme.onSurfaceVariant.withOpacity(0.5),
        ),
        todayDecoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(color: scheme.onPrimaryContainer),
        selectedDecoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(color: scheme.onPrimary),
        markerDecoration: BoxDecoration(
          color: context.status.pendingFg,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, String? avatarUrl) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileSettingsScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: 32,
          backgroundColor: scheme.surface,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Icon(Icons.person, color: scheme.onPrimaryContainer, size: 30)
              : null,
        ),
      ),
    );
  }

  // ==========================================
  // --- GOOGLE CALENDAR PANEL ---
  // ==========================================
  Widget _buildGoogleCalendarPanel(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Upcoming Schedule", style: theme.textTheme.headlineSmall),
            if (_isCalendarConnected)
              IconButton(
                icon: const Icon(Icons.sync),
                color: scheme.onSurfaceVariant,
                tooltip: "Refresh Schedule",
                onPressed: _checkGoogleCalendarConnection,
              ),
          ],
        ),
        const SizedBox(height: 24),

        // STATE 1: LOADING
        if (_isLoadingCalendar)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          )
        // STATE 2: NOT CONNECTED
        else if (!_isCalendarConnected)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.status.rejectedFg.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.status.rejectedBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: context.status.rejectedFg,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Not Connected",
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: context.status.rejectedFg,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Icon(
                  Icons.calendar_month_rounded,
                  size: 48,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  "Sync your Google Calendar",
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  "Connect your account to see your daily itinerary, "
                  "meetings, and events directly on your dashboard.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _handleConnectNowPressed,
                    icon: const Icon(Icons.link),
                    label: const Text("Connect Now"),
                  ),
                ),
              ],
            ),
          )
        // STATE 3: CONNECTED, NO EVENTS
        else if (_googleEvents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Center(
              child: Text(
                "Your schedule is clear. Enjoy your day.",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        // STATE 4: EVENTS
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _googleEvents.length,
            itemBuilder: (context, index) {
              final event = _googleEvents[index];

              final startTime = event.start?.dateTime ?? event.start?.date;
              final endTime = event.end?.dateTime ?? event.end?.date;

              String timeString = "TBD";
              if (startTime != null && endTime != null) {
                final startStr = DateFormat(
                  'h:mm a',
                ).format(startTime.toLocal());
                final endStr = DateFormat('h:mm a').format(endTime.toLocal());
                timeString = "$startStr - $endStr";
              } else if (startTime != null) {
                timeString = "All Day";
              }

              // Rotating accents so consecutive events are distinguishable.
              // Drawn from the status tokens, so they adapt per mode.
              final accents = [
                context.status.overtimeFg,
                context.status.pendingFg,
                context.status.earlyLeaveFg,
                context.status.approvedFg,
              ];

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildRealTaskCard(
                  context,
                  event.summary ?? "Busy",
                  timeString,
                  Icons.event,
                  accents[index % accents.length],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRealTaskCard(
    BuildContext context,
    String title,
    String time,
    IconData icon,
    Color accent,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: accent.withOpacity(0.15),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('profile_id', Supabase.instance.client.auth.currentUser!.id)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          unreadCount = snapshot.data!
              .where((n) => n['is_read'] == false)
              .length;
        }

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_none_rounded,
                color: scheme.onSurface,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: scheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onError,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
