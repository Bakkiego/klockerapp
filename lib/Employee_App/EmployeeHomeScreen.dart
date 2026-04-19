import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  _EmployeeHomeScreenState createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  bool isClockedIn = false;
  String currentTime = "00:00:00";

  void handleClockToggle() async {
    // 1. Trigger haptic FIRST (before the UI rebuilds)
    try {
      await HapticFeedback.vibrate();
      print("Vibration triggered!"); // Check your debug console for this!
    } catch (e) {
      print("Haptic error: $e");
    }

    // 2. Then update state
    if (mounted) {
      setState(() {
        isClockedIn = !isClockedIn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // 1. Fixed Background: Use theme background instead of light grey
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
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

    return GestureDetector(
      onTap: handleClockToggle,
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // 2. Fixed Button Color: Use surface color or a dark grey in dark mode
          color: isDark ? theme.colorScheme.surface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isClockedIn
                  ? const Color(0xFFFF4D4D).withOpacity(0.2)
                  : const Color(0xFF00A36C).withOpacity(0.2),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
          border: Border.all(
            color: isClockedIn
                ? const Color(0xFFFF4D4D)
                : const Color(0xFF00A36C),
            width: 8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isClockedIn ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 80,
              color: isClockedIn
                  ? const Color(0xFFFF4D4D)
                  : const Color(0xFF00A36C),
            ),
            Text(
              isClockedIn ? "CLOCK OUT" : "CLOCK IN",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: isClockedIn
                    ? const Color(0xFFFF4D4D)
                    : const Color(0xFF00A36C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 30),
      decoration: BoxDecoration(
        // 3. Fixed Header Color: Use card/surface color
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
                "Good Morning, Alex",
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Main Street Branch",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00A36C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: Color(0xFF00A36C)),
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
              value: "38.5h",
              icon: Icons.timer_outlined,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _summaryStat(
              context,
              label: "Next Shift",
              value: "Tomorrow, 08:00",
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Use your brand green for the background
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
          // White icon to contrast with green
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
              color: Colors.white, // Pure white text
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
