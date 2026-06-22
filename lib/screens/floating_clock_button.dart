import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';

class FloatingClockButton extends StatefulWidget {
  const FloatingClockButton({super.key});

  @override
  State<FloatingClockButton> createState() => _FloatingClockButtonState();
}

class _FloatingClockButtonState extends State<FloatingClockButton> {
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, dynamic>? _activeShift;

  // 🚀 NEW: Track if the Admin actually has a shift today
  bool _hasShiftToday = false;

  @override
  void initState() {
    super.initState();
    _fetchShiftStatus();
  }

  // 1. Silently check if the Admin is already clocked in AND if they have a shift
  Future<void> _fetchShiftStatus() async {
    setState(() => _isLoading = true);

    try {
      // Check if they are currently clocked in
      final shift = await SupabaseService().getActiveShift();

      // 🚀 NEW: Check if they are scheduled for today
      final upcomingShifts = await SupabaseService().getMyUpcomingShifts();
      DateTime now = DateTime.now();
      bool foundShiftToday = false;

      for (var s in upcomingShifts) {
        if (s['shift_date'] != null) {
          DateTime shiftDate = DateTime.parse(s['shift_date']);

          // 🚀 BULLETPROOF DATE CHECK
          if (shiftDate.year == now.year &&
              shiftDate.month == now.month &&
              shiftDate.day == now.day) {
            foundShiftToday = true;
            break; // We found one, stop checking!
          }
        }
      }

      if (mounted) {
        setState(() {
          _activeShift = shift;
          _hasShiftToday = foundShiftToday;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. The Geofence & Clock In/Out Engine
  Future<void> _handleClockToggle() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}

    setState(() => _isProcessing = true);

    try {
      // GPS Permissions
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
        // --- CLOCK OUT ---
        final DateTime clockInTime = DateTime.parse(_activeShift!['clock_in']);
        final int totalMinutes = DateTime.now()
            .difference(clockInTime)
            .inMinutes;

        await SupabaseService().clockOut(
          attendanceId: _activeShift!['id'],
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
        // --- CLOCK IN ---
        final assignedBranch = await SupabaseService().getAssignedBranch();

        if (assignedBranch == null) {
          throw Exception("You must assign yourself to a branch first!");
        }
        if (assignedBranch['gps_lat'] == null ||
            assignedBranch['gps_long'] == null) {
          throw Exception("Your branch doesn't have GPS coordinates set up.");
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
            "You are ${distanceInMeters.toStringAsFixed(0)}m away from the branch. Must be within ${allowedRadius}m.",
          );
        }

        await SupabaseService().clockIn(
          branchId: assignedBranch['id'],
          lat: userPosition.latitude,
          lng: userPosition.longitude,
          isVerified: true,
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

      // Refresh the button state (will unlock if they just clocked out and have no other shifts)
      await _fetchShiftStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const FloatingActionButton.extended(
        onPressed: null,
        backgroundColor: Colors.grey,
        label: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    final bool isClockedIn = _activeShift != null;

    // 🚀 NEW: Determine if the button should be locked
    final bool isLockedOut = !isClockedIn && !_hasShiftToday;

    // 🚀 NEW: Dynamic Button Color
    Color btnColor;
    if (isClockedIn) {
      btnColor = Colors.redAccent;
    } else if (isLockedOut) {
      btnColor = Colors.grey;
    } else {
      btnColor = const Color(0xFF00A36C);
    }

    return FloatingActionButton.extended(
      onPressed: _isProcessing
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
                return; // Stop the function
              }
              _handleClockToggle();
            },
      backgroundColor: btnColor,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: _isProcessing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Icon(
              isClockedIn
                  ? Icons.stop_rounded
                  : (isLockedOut
                        ? Icons.lock_outline_rounded
                        : Icons.play_arrow_rounded),
            ),
      label: Text(
        isClockedIn ? "Clock Out" : "Clock In",
        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}
