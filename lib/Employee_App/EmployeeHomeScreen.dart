import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart'; // <-- New import for date formatting
import 'package:klockerapp/providers/user_provider.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 🚀 Needed for the bell's realtime stream

// 🚀 IMPORT PROFILE SETTINGS & NOTIFICATIONS (Verify paths match your project!)
import 'package:klockerapp/screens/help-screens/profile_settings_screen.dart';
import 'package:klockerapp/components/notifications_screen.dart'; // 🚀 Added Notifications import

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  _EmployeeHomeScreenState createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, dynamic>? _activeShift;
  bool _hasShiftToday = false;
  String _assignedBranchName = "Loading...";
  String _nextShiftDisplay = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  // --- 1. CHECK IF ALREADY CLOCKED IN & FETCH NEXT SHIFT ---
  Future<void> _loadInitialState() async {
    setState(() => _isLoading = true);
    try {
      // 1. Check if they are clocked in
      final shift = await SupabaseService().getActiveShift();

      // 2. Look up the name of their Assigned Branch
      final branch = await SupabaseService().getAssignedBranch();

      // 3. Fetch the very next upcoming shift
      final upcomingShifts = await SupabaseService().getMyUpcomingShifts();
      String formattedNextShift = "No scheduled shifts";
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      bool foundShiftToday = false;

      for (var s in upcomingShifts) {
        final String dateStr = s['shift_date'];
        final template = s['shift_templates'] ?? {};
        final String startTimeStr = template['start_time'] ?? '00:00:00';
        DateTime shiftDate = DateTime.parse(dateStr);
        if (shiftDate.isAtSameMomentAs(today)) {
          foundShiftToday = true;
        }

        // Parse the exact hour and minute of the shift
        final List<String> timeParts = startTimeStr.split(':');
        int hours = int.tryParse(timeParts[0]) ?? 0;
        int minutes = timeParts.length > 1
            ? int.tryParse(timeParts[1]) ?? 0
            : 0;
        DateTime exactShiftStart = DateTime(
          shiftDate.year,
          shiftDate.month,
          shiftDate.day,
          hours,
          minutes,
        );

        // STRCIT CHECK: Is this shift actually in the future?
        if (exactShiftStart.isAfter(now)) {
          String timeString = startTimeStr.length >= 5
              ? startTimeStr.substring(0, 5)
              : startTimeStr;
          DateTime today = DateTime(now.year, now.month, now.day);
          DateTime tomorrow = today.add(const Duration(days: 1));

          if (shiftDate.isAtSameMomentAs(today)) {
            formattedNextShift = "Today, $timeString";
          } else if (shiftDate.isAtSameMomentAs(tomorrow)) {
            formattedNextShift = "Tomorrow, $timeString";
          } else {
            formattedNextShift =
                "${DateFormat('MMM d').format(shiftDate)}, $timeString";
          }

          break; // We found the true *next* shift, stop looking!
        }
      }

      if (mounted) {
        setState(() {
          _activeShift = shift;
          _assignedBranchName = branch?['name'] ?? "No Assigned Branch";
          _nextShiftDisplay = formattedNextShift;
          _hasShiftToday = foundShiftToday;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() {
          _nextShiftDisplay = "Error loading";
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. THE STRICT GEOFENCE ENGINE ---
  Future<void> handleClockToggle() async {
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      print("Haptic error: $e");
    }

    setState(() => _isProcessing = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Please turn on your phone GPS.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied.');
        }
      }

      Position userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_activeShift != null) {
        // --- CLOCK OUT LOGIC ---
        final DateTime clockInTime = DateTime.parse(_activeShift!['clock_in']);
        final DateTime clockOutTime = DateTime.now();
        final int totalMinutes = clockOutTime.difference(clockInTime).inMinutes;
        final String attendanceId = _activeShift!['id'];

        // 🚀 UPDATED: Now passing the outLat and outLng!
        await SupabaseService().clockOut(
          attendanceId: attendanceId,
          totalMinutesWorked: totalMinutes,
          outLat: userPosition.latitude,
          outLng: userPosition.longitude,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Clocked Out Successfully!"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // --- CLOCK IN LOGIC ---
        final assignedBranch = await SupabaseService().getAssignedBranch();

        if (assignedBranch == null) {
          throw Exception("Could not locate your assigned branch data.");
        }
        if (assignedBranch['gps_lat'] == null ||
            assignedBranch['gps_long'] == null) {
          throw Exception(
            "${assignedBranch['name']} does not have GPS coordinates set up!",
          );
        }

        double distanceInMeters = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          assignedBranch['gps_lat'],
          assignedBranch['gps_long'],
        );

        int allowedRadius = assignedBranch['radius_meters'] ?? 100;

        if (distanceInMeters > allowedRadius) {
          throw Exception(
            "You are ${distanceInMeters.toStringAsFixed(0)}m away from your assigned branch (${assignedBranch['name']}). You must be within ${allowedRadius}m to clock in!",
          );
        }

        // Inside your clock-in button logic:
        await SupabaseService().clockIn(
          branchId: assignedBranch['id'],
          lat: userPosition.latitude,
          lng: userPosition.longitude,
          isVerified: true, // You've already checked the geofence in the UI
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Clocked into ${assignedBranch['name']}!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      await _loadInitialState();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Action Failed"),
            content: Text(e.toString().replaceAll("Exception: ", "")),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : Column(
              children: [
                _buildEmployeeHeader(context),
                Expanded(child: Center(child: _buildClockButton(context))),
                _buildShiftSummary(context),
              ],
            ),
    );
  }

  Widget _buildClockButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool isClockedIn = _activeShift != null;

    // 🚀 NEW: Determine if the button should be locked
    final bool isLockedOut = !isClockedIn && !_hasShiftToday;

    // Determine Button Color dynamically
    Color ringColor;
    if (isClockedIn) {
      ringColor = const Color(0xFFFF4D4D); // Red for Clock Out
    } else if (isLockedOut) {
      ringColor = Colors.grey; // Grey for Locked
    } else {
      ringColor = const Color(0xFF00A36C); // Green for Clock In
    }

    return GestureDetector(
      onTap: _isProcessing
          ? null
          : () {
              // 🚀 NEW: Intercept the tap if they are locked out!
              if (isLockedOut) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("No shifts scheduled for today!"),
                    backgroundColor: Colors.grey[800],
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return; // Stop the function completely
              }

              // Otherwise, run the normal clock in/out geofence logic
              handleClockToggle();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? theme.colorScheme.surface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: ringColor.withOpacity(0.2),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
          border: Border.all(color: ringColor, width: 8),
        ),
        child: _isProcessing
            ? Center(child: CircularProgressIndicator(color: ringColor))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isClockedIn
                        ? Icons.stop_rounded
                        : (isLockedOut
                              ? Icons.lock_outline_rounded
                              : Icons.play_arrow_rounded),
                    size: 80,
                    color: ringColor,
                  ),
                  Text(
                    isClockedIn ? "CLOCK OUT" : "CLOCK IN",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: ringColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Quick helper to make the app feel alive based on the time of day!
  String _getGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning, $name";
    if (hour < 17) return "Good Afternoon, $name";
    return "Good Evening, $name";
  }

  Widget _buildEmployeeHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 🚀 READ DATA DIRECTLY FROM THE PROVIDER
    final userProvider = context.watch<UserProvider>();
    final fullName = userProvider.fullName ?? 'Employee';
    final firstName = fullName.split(' ').first;
    final avatarUrl = userProvider.avatarUrl;

    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 30),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(firstName), // 🚀 DYNAMIC GREETING
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _assignedBranchName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),

          // 🚀 NEW: Wrap the Avatar in a Row and add the Bell!
          Row(
            children: [
              _buildNotificationBell(context),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileSettingsScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A36C).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? const Icon(
                            Icons.person,
                            color: Color(0xFF00A36C),
                            size: 25,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 40),
      child: Row(
        children: [
          Expanded(
            child: _summaryStat(
              context,
              label: "Total Hours",
              value: "38.5h", // Placeholder for future feature
              icon: Icons.timer_outlined,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _summaryStat(
              context,
              label: "Next Shift",
              value: _nextShiftDisplay, // <-- Injected live data here
              icon: Icons.calendar_today_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00A36C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A36C).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 🚀 NEW: The Real-Time Notification Bell Function
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
