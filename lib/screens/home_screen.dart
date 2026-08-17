import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:klockerapp/components/notifications_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:googleapis/calendar/v3.dart' as calendar; // 🚀 NEW: Google API
import 'package:table_calendar/table_calendar.dart'; // 🚀 NEW
import 'package:klockerapp/providers/user_provider.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:klockerapp/supabase/google_calendar_service.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/attendance_summary.dart';
import 'package:klockerapp/screens/floating_clock_button.dart';
import 'package:klockerapp/screens/help-screens/profile_settings_screen.dart';
import 'dart:async';
import 'help-screens/social_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  static String id = 'home_screen';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

  // 🚀 NEW: Google Calendar State Variables
  final GoogleCalendarService _calendarService = GoogleCalendarService();
  StreamSubscription<GoogleSignInAccount?>? _authSub;
  List<calendar.Event> _googleEvents = [];
  bool _isCalendarConnected = false;
  bool _isLoadingCalendar = true; // Start loading while we check silent sign-in

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

  Future<void> _initGoogleCalendar() async {
    final connected = await _calendarService
        .restoreSession(); // cheap after the first call, ever
    if (!mounted) return;
    setState(() => _isCalendarConnected = connected);
    if (connected) {
      await _checkGoogleCalendarConnection(); // fetch events, now that we know we're connected
    } else {
      setState(() => _isLoadingCalendar = false);
    }
  }

  // ==========================================
  // --- 🚀 GOOGLE CALENDAR LOGIC ---
  // ==========================================
  // 🚀 Add this map to hold your events by date
  Map<DateTime, List<dynamic>> _calendarMarkers = {};

  // Helper to strip the time off a date so the calendar can match it
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

    // Direct, uninterrupted call from this tap — this is what makes the
    // real Calendar consent popup actually show up.
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

  //Update your google calendar fetcher to populate the map
  Future<void> _checkGoogleCalendarConnection() async {
    setState(() => _isLoadingCalendar = true);
    try {
      final events = await _calendarService.getUpcomingEvents();

      // Group the events by Date for the TableCalendar
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
    return "Good Evenings, $name";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
      backgroundColor: theme.scaffoldBackgroundColor,
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
              // --- 1. THE DYNAMIC HEADER ---
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
                                style: TextStyle(
                                  fontSize: 18,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _tenantName,
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.titleLarge?.color,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 650),
                              child: SearchBar(
                                // ... (Keep your existing SearchBar code here)
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerRight,
                            // 🚀 NEW: A Row to hold BOTH the Bell and the Avatar
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildNotificationBell(context),
                                const SizedBox(width: 16),
                                _buildAvatar(context, avatarUrl, isDark),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGreeting(firstName),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _tenantName,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.titleLarge?.color,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            // 🚀 NEW: A Row to hold BOTH the Bell and the Avatar for Mobile!
                            Row(
                              children: [
                                _buildNotificationBell(context),
                                const SizedBox(width: 12),
                                _buildAvatar(context, avatarUrl, isDark),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SearchBar(
                          elevation: WidgetStateProperty.all(0),
                          backgroundColor: WidgetStateProperty.all(
                            isDark ? Colors.grey[900] : Colors.grey[200],
                          ),
                          hintText: 'Search features...',
                          leading: const Padding(
                            padding: EdgeInsets.only(left: 12.0, right: 8.0),
                            child: Icon(Icons.search, color: Colors.grey),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF00A36C),
                                ),
                              ),
                            )
                          : AttendanceSummary(records: _selectedDateRecords),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 50),
              Divider(color: Colors.grey.withOpacity(0.1)),
              const SizedBox(height: 40),

              // --- 3. THE CALENDAR & TASKS SPLIT ---
              isWeb
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 550,
                            child: // 🚀 UPGRADED TO TABLE CALENDAR
                            TableCalendar(
                              firstDay: DateTime(2024),
                              lastDay: DateTime(2030),
                              focusedDay: _selectedDate,
                              currentDay: DateTime.now(),
                              selectedDayPredicate: (day) =>
                                  isSameDay(_selectedDate, day),
                              onDaySelected: (selectedDay, focusedDay) {
                                if (!isSameDay(_selectedDate, selectedDay)) {
                                  _fetchAttendanceForDate(selectedDay);
                                }
                              },
                              // This is what puts the dots on the dates!
                              eventLoader: (day) {
                                return _calendarMarkers[_normalizeDate(day)] ??
                                    [];
                              },
                              headerStyle: const HeaderStyle(
                                formatButtonVisible:
                                    false, // Hide the "2 weeks" button
                                titleCentered: true,
                              ),
                              calendarStyle: CalendarStyle(
                                todayDecoration: BoxDecoration(
                                  color: const Color(
                                    0xFF00A36C,
                                  ).withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                selectedDecoration: const BoxDecoration(
                                  color: Color(0xFF00A36C),
                                  shape: BoxShape.circle,
                                ),
                                // Style the little badges
                                markerDecoration: const BoxDecoration(
                                  color:
                                      Colors.orange, // Orange dots for meetings
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 550,
                          width: 1,
                          color: Colors.grey.withOpacity(0.2),
                          margin: const EdgeInsets.symmetric(horizontal: 50),
                        ),
                        // 🚀 REPLACED: Now calls the Real Google Panel
                        Expanded(
                          flex: 2,
                          child: _buildGoogleCalendarPanel(isDark),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        SizedBox(
                          height: 400,
                          child: // 🚀 UPGRADED TO TABLE CALENDAR
                          TableCalendar(
                            firstDay: DateTime(2024),
                            lastDay: DateTime(2030),
                            focusedDay: _selectedDate,
                            currentDay: DateTime.now(),
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDate, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              if (!isSameDay(_selectedDate, selectedDay)) {
                                _fetchAttendanceForDate(selectedDay);
                              }
                            },
                            // This is what puts the dots on the dates!
                            eventLoader: (day) {
                              return _calendarMarkers[_normalizeDate(day)] ??
                                  [];
                            },
                            headerStyle: const HeaderStyle(
                              formatButtonVisible:
                                  false, // Hide the "2 weeks" button
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
                              // Style the little badges
                              markerDecoration: const BoxDecoration(
                                color:
                                    Colors.orange, // Orange dots for meetings
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Divider(color: Colors.grey.withOpacity(0.1)),
                        const SizedBox(height: 30),
                        // 🚀 REPLACED: Now calls the Real Google Panel
                        _buildGoogleCalendarPanel(isDark),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, String? avatarUrl, bool isDark) {
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
          color: const Color(0xFF00A36C).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: 32,
          backgroundColor: isDark ? Colors.grey[800] : Colors.white,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? const Icon(Icons.person, color: Color(0xFF00A36C), size: 30)
              : null,
        ),
      ),
    );
  }

  // ==========================================
  // --- 🚀 THE NEW GOOGLE CALENDAR UI ---
  // ==========================================
  Widget _buildGoogleCalendarPanel(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Upcoming Schedule",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (_isCalendarConnected)
              // 🚀 CHANGED from Icon to IconButton so it's clickable!
              IconButton(
                icon: const Icon(Icons.sync),
                color: Colors.grey.withOpacity(0.5),
                tooltip: "Refresh Schedule",
                onPressed: () {
                  // 🚀 Triggers the refresh manually!
                  _checkGoogleCalendarConnection();
                },
              ),
          ],
        ),
        const SizedBox(height: 24),

        // STATE 1: LOADING
        if (_isLoadingCalendar)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            ),
          )
        // STATE 2: NOT CONNECTED (Show Auth Button)
        // STATE 2: NOT CONNECTED (Show Auth Button)
        else if (!_isCalendarConnected)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 2,
              ), // 🚀 Red border to grab attention
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🚀 Status Badge from Settings
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Sync your Google Calendar",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Connect your account to see your daily itinerary, meetings, and events directly on your dashboard.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  // 🚀 THE FIX: Push to settings, wait, and refresh!
                  onPressed: _handleConnectNowPressed,
                  icon: const Icon(Icons.link),
                  label: const Text(
                    "Connect Now",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A36C),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          )
        // STATE 3: CONNECTED, BUT NO EVENTS
        else if (_googleEvents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(
              child: Text(
                "Your schedule is clear! Enjoy your day.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          )
        // STATE 4: CONNECTED & SHOWING REAL EVENTS
        else
          ListView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(), // Let the main SingleChildScrollView handle scrolling
            itemCount: _googleEvents.length,
            itemBuilder: (context, index) {
              final event = _googleEvents[index];

              // Extract and format the time (Handles both "All Day" and specific times)
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

              // Alternate colors slightly for visual appeal just like the mockup
              final colors = [
                Colors.blue,
                Colors.orange,
                Colors.purple,
                Colors.green,
              ];
              final cardColor = colors[index % colors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildRealTaskCard(
                  event.summary ?? "Busy", // Google's term for Title
                  timeString,
                  Icons.event,
                  cardColor,
                  isDark,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRealTaskCard(
    String title,
    String time,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
              onPressed: () {
                // TODO: Make sure you import NotificationsScreen at the top!
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
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).cardColor,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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
