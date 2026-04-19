import 'package:flutter/material.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klockerapp/models/app_enums.dart';

abstract class KlockerAdapter {
  // --- AUTHENTICATION & PROFILE ---

  final supabase = Supabase.instance.client;

  // Helper to generate the 6-digit code
  String generateInviteCode() {
    const String chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(Random().nextInt(chars.length)),
      ),
    );
  }

  /// Sign up as Administrator (Creates a new Tenant/Organization)
  Future<void> createAdminAccount({
    required String email,
    required String password,
    required String businessName,
    required String fullName,
    required BuildContext context,
  }) async {
    try {
      print("🚀 Attempting Auth Sign Up for: $email");

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        print("❌ Auth failed: User is null");
        return;
      }

      print("✅ Auth Success! User ID: ${response.user!.id}");

      // Proceed to Tenant/Profile creation...
    } catch (e) {
      print("🔴 CRITICAL ERROR: $e"); // THIS WILL SHOW IN YOUR TERMINAL
      if (context.mounted) {
        _showError(context, "Signup Failed: $e");
      }
    }
  }

  /// Sign up as Employee (Joins an existing Organization via Invite Code)
  Future createEmployeeAccount({
    required String email,
    required String password,
    required String inviteCode,
    required String fullName,
    required BuildContext context,
  });

  /// Sign in existing user
  Future signInUser(String email, String password, BuildContext context);

  /// Get profile info (Includes Role: Manager or Employee)
  Future getUserProfile(BuildContext context);

  // --- ORGANIZATION & BRANCH MANAGEMENT ---

  /// Get the details of the company the user belongs to
  Future getOrganizationDetails(BuildContext context);

  /// Create a new office/branch location (Manager only)
  Future createBranch({
    required String branchName,
    required double latitude,
    required double longitude,
    required double radius,
    required BuildContext context,
  });

  /// Get list of all branches for the current organization
  Future getBranches(BuildContext context);

  // --- ATTENDANCE & TRACKING ---

  /// The core "Clock In" function with GPS verification
  Future clockIn({
    required String branchId,
    required double currentLat,
    required double currentLong,
    required BuildContext context,
  });

  /// The "Clock Out" function
  Future clockOut({
    required String attendanceId,
    required BuildContext context,
  });

  /// Get all attendance logs for the current user
  Future getMyAttendanceHistory(BuildContext context);

  /// Get ALL employee attendance logs (Manager only)
  Future getTeamAttendance(BuildContext context);

  // --- NOTIFICATIONS & ALERTS ---

  /// Stream of real-time alerts (e.g., Early Departure alerts for Managers)
  Stream<List<Map<String, dynamic>>> getNotificationsStream();

  /// Get historical notifications
  Future<List<Map<String, dynamic>>> getMyNotifications();

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00A36C), // Your brand green
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
