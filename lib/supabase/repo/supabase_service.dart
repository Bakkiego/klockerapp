import 'dart:math';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/app_enums.dart';
import '../../services/key_service.dart';
import '../../services/chat_crypto.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // ==========================================
  // --- IN-APP NOTIFICATIONS ENGINE ---
  // ==========================================

  Future<List<Map<String, dynamic>>> getMyNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('notifications')
        .select('*')
        .eq('profile_id', user.id)
        .order('created_at', ascending: false)
        .limit(50); // Only keep the 50 most recent

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  // Helper 1: Send a 1-to-1 notification
  Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String message,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    await _supabase.from('notifications').insert({
      'tenant_id': profile['tenant_id'],
      'profile_id': recipientId, // Who receives it
      'title': title,
      'message': message,
      'is_read': false,
    });
  }

  // 🚀 Helper 2: Send a mass notification to ALL active employees in the company
  Future<void> sendMassNotification({
    required String title,
    required String message,
    String? branchId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final profile = await _supabase
          .from('profiles')
          .select('tenant_id')
          .eq('id', user.id)
          .single();
      final tenantId = profile['tenant_id'];

      var query = _supabase
          .from('profiles')
          .select('id')
          .eq('tenant_id', tenantId);

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }

      final employees = await query;

      final List<Map<String, dynamic>> notifications = employees
          .map(
            (emp) => {
              'tenant_id': tenantId,
              'profile_id': emp['id'],
              'title': title,
              'message': message,
              'is_read': false,
            },
          )
          .toList();

      if (notifications.isNotEmpty) {
        await _supabase.from('notifications').insert(notifications);
      }
    } catch (e) {
      debugPrint("Mass Notification Error: $e");
    }
  }

  // 🚀 Helper 3: Alert the Business Owner directly (for late leaves, deductions, etc.)
  Future<void> notifyBusinessOwner({
    required String title,
    required String message,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final profile = await _supabase
          .from('profiles')
          .select('tenant_id')
          .eq('id', user.id)
          .single();

      final tenant = await _supabase
          .from('tenants')
          .select('admin_id')
          .eq('id', profile['tenant_id'])
          .single();

      // Don't ping the owner about their own actions
      if (user.id != tenant['admin_id']) {
        await sendNotification(
          recipientId: tenant['admin_id'],
          title: title,
          message: message,
        );
      }
    } catch (e) {
      debugPrint("Business Owner Notification Error: $e");
    }
  }

  // ==========================================
  // NEW METHODS ADDED FOR ROUTING & AUTH GATE
  // ==========================================

  // 1. Helper to convert DB String to Enum
  userRole mapStringToRole(String? roleName) {
    return userRole.fromString(roleName);
  }

  // 2. Fetch a single profile for the AuthGate in main.dart
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select('*, tenants(name, subscription_tier)')
        .eq('id', userId)
        .maybeSingle(); // 🚀 Prevents the JSON crash!

    if (response == null) throw Exception("Profile not found.");

    // 🚀 Flatten the data so the app can read it instantly
    if (response['tenants'] != null) {
      response['company_name'] = response['tenants']['name'];
      response['subscription_tier'] = response['tenants']['subscription_tier'];
    }

    return response;
  }

  // ==========================================
  // EXISTING METHODS (UPDATED)
  // ==========================================

  // LOGIN: Simple and clean
  Future<AuthResponse> login(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // SIGNUP ADMIN: Matches your exact schema requirements
  Future<Map<String, dynamic>> signUpAdmin({
    required String email,
    required String password,
    required String fullName,
    required String businessName,
    required int phoneNumber,
  }) async {
    // 1. Generate a unique code (e.g., first 4 letters of business + random number)
    String generatedCode =
        "${businessName.replaceAll(' ', '').toUpperCase().substring(0, 4)}-${DateTime.now().millisecond}";

    // 2. Create the Auth User first
    final AuthResponse res = await _supabase.auth.signUp(
      email: email.trim(),
      password: password.trim(),
    );

    final user = res.user;
    if (user == null) throw "Signup failed - No user returned";

    // 3. Create the Tenant (Must include admin_id!)
    final tenantData = await _supabase
        .from('tenants')
        .insert({
          'name': businessName,
          'company_code': generatedCode,
          'admin_id': user.id,
        })
        .select()
        .single();

    final String tenantId = tenantData['id'];

    // 4. Create the Profile (UPDATED TO USE YOUR ENUM!)
    await _supabase.from('profiles').insert({
      'id': user.id,
      'tenant_id': tenantId,
      'full_name': fullName,
      'role': userRole.Manager.toSql, // <-- The enum is used here now!
      'created_at': DateTime.now().toIso8601String(),
      'phone_num': phoneNumber,
      'email': email,
    });
    // Fetch and return the newly created profile so the UI can log them in
    if (user == null) throw Exception("Sign up failed");

    final profileData = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return profileData;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<Map<String, dynamic>> signInUser(String email, String password) async {
    final AuthResponse res = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final userId = res.user!.id;

    debugPrint('Starting chat identity check...');
    bool chatReady = true;
    try {
      if (!await KeyService.hasLocalKey()) {
        debugPrint('No local key found, checking profile...');
        final profile = await getUserProfile(userId);
        if (profile['public_key'] == null) {
          debugPrint('Setting up new identity...');
          await KeyService.setupNewIdentity(userId, password.trim());
          debugPrint('New identity setup complete.');
        } else {
          debugPrint('Restoring from password...');
          chatReady = await KeyService.restoreFromPassword(
            userId,
            password.trim(),
          );
          debugPrint('Restore result: $chatReady');
        }
      } else {
        debugPrint('Local key already present.');
      }
    } catch (e) {
      debugPrint('Chat identity setup/restore failed: $e');
      chatReady = false;
    }
    debugPrint('Final chatReady value: $chatReady');

    final user = res.user;
    if (user == null) throw "Sign in failed - No user returned";

    //get the user's profile AND billing status
    final data = await _supabase
        .from('profiles')
        .select('*, tenants(name, subscription_tier)') //  Fetch the tier!
        .eq('id', user.id)
        .maybeSingle(); //  Prevents the JSON crash

    if (data == null) throw Exception("Profile data is missing.");

    //  Flatten the data
    if (data['tenants'] != null) {
      data['company_name'] = data['tenants']['name'];
      data['subscription_tier'] = data['tenants']['subscription_tier'];
    }

    return data;
  }

  Future<List<Map<String, dynamic>>> getEmployees() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final tenantId = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final List<Map<String, dynamic>> employees = await _supabase
        .from('profiles')
        .select('*')
        .eq('tenant_id', tenantId['tenant_id'])
        .order('full_name', ascending: true);
    return employees;
  }

  Future<void> updateEmployeeProfile({
    required String employeeId,
    required Map<String, dynamic> updates,
  }) async {
    await _supabase.from('profiles').update(updates).eq('id', employeeId);
  }

  // 1. Verify the Company Code
  Future<Map<String, dynamic>?> verifyCompanyCode(String code) async {
    final response = await _supabase
        .from('tenants')
        .select('id, name')
        .eq('company_code', code)
        .maybeSingle();

    return response;
  }

  // 2. Sign Up the Employee
  Future<void> signUpEmployee({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String tenantId,
  }) async {
    final AuthResponse res = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final String? userId = res.user?.id;

    if (userId != null) {
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');

      await _supabase.from('profiles').insert({
        'id': userId,
        'full_name': fullName,
        'phone_num': int.tryParse(cleanPhone) ?? 0,
        'role': userRole.Employee.toSql, // Also using your enum here!
        'tenant_id': tenantId,
        'email': email,
        'must_change_password': true,
      });
    }
  }

  Future<void> deleteEmployee(String id) async {
    await _supabase.from('profiles').delete().eq('id', id);
  }

  Future<List<String>> getBranchNames() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final profile = await _supabase
          .from('profiles')
          .select('tenant_id')
          .eq('id', user.id)
          .single();

      final String tenantId = profile['tenant_id'];

      final List<dynamic> data = await _supabase
          .from('branches')
          .select('name')
          .eq('tenant_id', tenantId)
          .order('name', ascending: true);

      return data.map((item) => item['name'] as String).toList();
    } catch (e) {
      print("Error fetching branches: $e");
      return ["Error loading branches"];
    }
  }

  Future<List<String>> getDepartmentNames() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final profile = await _supabase
          .from('profiles')
          .select('tenant_id')
          .eq('id', user.id)
          .single();

      final List<dynamic> data = await _supabase
          .from('departments')
          .select('name')
          .eq('tenant_id', profile['tenant_id'])
          .order('name', ascending: true);

      return data.map((item) => item['name'] as String).toList();
    } catch (e) {
      return ["Error loading departments"];
    }
  }
  // ==========================================
  // BRANCH LOCATION SETUP (ADMIN)
  // ==========================================

  Future<String> _myTenantId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();
    return profile['tenant_id'] as String;
  }

  // 1. Fetch the branches so the Admin can select WHICH branch they are standing in
  Future<List<Map<String, dynamic>>> getAdminBranches() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final List<dynamic> data = await _supabase
        .from('branches')
        .select('*')
        .eq('tenant_id', profile['tenant_id'] as Object)
        .order('name', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  // Update a branch name

  Future<void> updateBranchName(
    String branchId,
    String newName,
    String address,
  ) async {
    await _supabase
        .from('branches')
        .update({'name': newName.trim(), 'address': address.trim()})
        .eq('id', branchId)
        .eq('tenant_id', await _myTenantId());
  }

  // Delete a branch
  Future<void> deleteBranch(String branchId) async {
    await _supabase
        .from('branches')
        .delete()
        .eq('id', branchId)
        .eq('tenant_id', await _myTenantId());
  }

  // 2. Create a new branch (The missing piece)
  Future<void> createBranch(String branchName, String address) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // Get the admin's tenant_id from their profile
    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    // Insert the new branch
    await _supabase.from('branches').insert({
      'tenant_id': profile['tenant_id'],
      'name': branchName.trim(),
      'address': address.trim(),
    });
  }

  // 2. Save the GPS coordinates to the database
  Future<void> updateBranchLocation({
    required String branchId,
    required double lat,
    required double lng,
    required int radiusMeters,
    required String newAddress,
  }) async {
    await _supabase
        .from('branches')
        .update({
          'gps_lat': lat,
          'gps_long': lng,
          'radius_meters': radiusMeters,
          'address': newAddress.trim(),
        })
        .eq('id', branchId)
        .eq('tenant_id', await _myTenantId());
  }
  // ==========================================
  // EMPLOYEE ATTENDANCE HISTORY
  // ==========================================

  // Fetch the logged-in employee's attendance records
  Future<List<Map<String, dynamic>>> getMyAttendance() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    // Notice we don't even need to pass the tenant_id or profile_id in the filter!
    // Our RLS policies handle the security automatically, but adding .eq() makes it faster.
    final data = await _supabase
        .from('attendance')
        .select('*')
        .eq('profile_id', user.id)
        .order('clock_in', ascending: false); // Newest shifts at the top

    return List<Map<String, dynamic>>.from(data);
  }

  // ==========================================
  // CLOCK IN / OUT SYSTEM
  // ==========================================

  // 1. Check if the user is currently clocked in
  Future<Map<String, dynamic>?> getActiveShift() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final data = await _supabase
        .from('attendance')
        .select('*')
        .eq('profile_id', user.id)
        .isFilter('clock_out', null) // 🚀 FIXED: Updated to the new v2 syntax!
        .order('clock_in', ascending: false)
        .limit(1);

    return data.isNotEmpty ? data.first : null;
  }

  // ==========================================
  // LEAVE REQUESTS (EMPLOYEE)
  // ==========================================

  Future<void> submitLeaveRequest({
    required DateTime startDate,
    required DateTime endDate,
    required String leaveType,
    required String reason,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // 1. Grab their tenant_id
    final profile = await _supabase
        .from('profiles')
        .select('tenant_id, full_name')
        .eq('id', user.id)
        .single();

    // 2. Calculate 'total_days' for your database schema
    // We add +1 so that picking Monday to Wednesday counts as 3 days, not 2!
    final totalDays = endDate.difference(startDate).inDays + 1;

    // 3. Insert matching your EXACT schema
    await _supabase.from('leave_requests').insert({
      'tenant_id': profile['tenant_id'],
      'profile_id': user.id,
      'leave_type': leaveType,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'total_days': totalDays, // <-- New!
      'reason': reason, // <-- Now this will work!
      'status': 'pending', // Lowercase 'pending' to match your DB default
    });

    // 🚀 NOTIFICATION TRIGGER: Tell the Admin!
    await notifyBusinessOwner(
      title: "New Leave Request",
      message:
          "${profile['full_name']} requested $totalDays days of $leaveType.",
    );
  }

  Future<List<Map<String, dynamic>>> getPendingLeaveRequests() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // Grab the manager's tenant_id
    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    // Fetch the requests AND magically join the profiles table to get the Employee's name!
    final data = await _supabase
        .from('leave_requests')
        .select('''
          *,
          profiles!profile_id (full_name) 
        ''')
        .eq('tenant_id', profile['tenant_id'])
        .ilike('status', 'pending')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getAllCompanyLeaveRequests() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final data = await _supabase
        .from('leave_requests')
        .select('''
          *,
          profiles!profile_id (full_name,avatar_url) 
        ''')
        .eq('tenant_id', profile['tenant_id'])
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ==========================================
  // MANAGER: LIVE ATTENDANCE (DATE SPECIFIC)
  // ==========================================
  // Fetch Attendance by Date Range
  Future<List<Map<String, dynamic>>> getCompanyAttendanceByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();
    final tenantId = profile['tenant_id'];

    // 1. Formatting date boundaries
    // Roster bounds (YYYY-MM-DD)
    final String startStr =
        "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";
    final String endStr =
        "${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}";

    // Attendance bounds (UTC ISO Strings)
    final startIso = DateTime(
      start.year,
      start.month,
      start.day,
    ).toUtc().toIso8601String();
    final endIso = DateTime(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
    ).toUtc().toIso8601String();

    // 2. Fetch SCHEDULED shifts for the entire range
    final scheduledRosters = await _supabase
        .from('rosters')
        .select('''
        profile_id,
        shift_date,
        profiles!inner(full_name),
        shift_templates!inner(start_time)
      ''')
        .eq('tenant_id', tenantId)
        .gte('shift_date', startStr)
        .lte('shift_date', endStr);

    // 3. Fetch ACTUAL clock-ins for the entire range
    final actualAttendance = await _supabase
        .from('attendance')
        .select('*, profiles!profile_id(full_name)')
        .eq('tenant_id', tenantId)
        .gte('clock_in', startIso)
        .lte('clock_in', endIso);

    List<Map<String, dynamic>> finalReport = [];
    Set<String> claimedAttendanceIds = {};
    DateTime currentRealTime = DateTime.now();

    // 4. Cross-Reference Logic (Schedule vs Reality)
    for (var roster in scheduledRosters) {
      final profileId = roster['profile_id'];
      final employeeName =
          roster['profiles']?['full_name'] ?? 'Unknown Employee';
      final String shiftDateStr = roster['shift_date'];
      final String startTimeStr =
          roster['shift_templates']?['start_time'] ?? '00:00:00';

      // Parse the roster's exact date and time
      final shiftDateParts = shiftDateStr.split('-');
      final List<String> timeParts = startTimeStr.split(':');
      final expectedStartTime = DateTime(
        int.parse(shiftDateParts[0]),
        int.parse(shiftDateParts[1]),
        int.parse(shiftDateParts[2]),
        int.tryParse(timeParts[0]) ?? 0,
        timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0,
      );

      // Look for a matching punch-in for THIS specific employee on THIS specific date
      Map<String, dynamic>? matchedRecord;
      for (var record in actualAttendance) {
        String attDateStr = record['date'] ?? '';

        // Fallback: If 'date' column is empty, grab it from clock_in
        if (attDateStr.isEmpty && record['clock_in'] != null) {
          final localClockIn = DateTime.parse(record['clock_in']).toLocal();
          attDateStr =
              "${localClockIn.year}-${localClockIn.month.toString().padLeft(2, '0')}-${localClockIn.day.toString().padLeft(2, '0')}";
        }

        if (record['profile_id'] == profileId &&
            attDateStr == shiftDateStr &&
            !claimedAttendanceIds.contains(record['id'])) {
          matchedRecord = record;
          break;
        }
      }

      if (matchedRecord != null) {
        // --- THEY CLOCKED IN ---
        claimedAttendanceIds.add(matchedRecord['id']);
        final actualClockIn = DateTime.parse(
          matchedRecord['clock_in'],
        ).toLocal();
        final isLate =
            actualClockIn.difference(expectedStartTime).inMinutes > 0;

        final String dbStatus =
            matchedRecord['status']?.toString().toLowerCase() ?? 'active';
        final bool isOt = matchedRecord['is_overtime'] == true;
        final bool otApproved = matchedRecord['overtime_approved'] == true;
        final bool earlyLeaveApproved =
            matchedRecord['early_leave_approved'] == true;

        String rawStatus = dbStatus;
        if (isOt && !otApproved) {
          rawStatus = 'overtime_pending';
        } else if (dbStatus == 'early_leave_pending' && !earlyLeaveApproved) {
          rawStatus = 'early_leave_pending';
        }

        String displayStatus = 'Present';
        if (dbStatus == 'absent')
          displayStatus = 'Absent';
        else if (isLate)
          displayStatus = 'Late';

        finalReport.add({
          'id': matchedRecord['id'],
          'name': employeeName,
          'clock_in': matchedRecord['clock_in'],
          'clock_out': matchedRecord['clock_out'],
          'status': displayStatus,
          'raw_status': rawStatus,
          'is_late': isLate,
          'expected_start': expectedStartTime.toIso8601String(),
          'overtime_minutes': matchedRecord['overtime_minutes'],
        });
      } else {
        // --- THEY DID NOT CLOCK IN (Generate Virtual Absent Row) ---
        String status = currentRealTime.isAfter(expectedStartTime)
            ? 'Absent'
            : 'Upcoming';
        finalReport.add({
          'name': employeeName,
          'clock_in': null,
          'clock_out': null,
          'expected_start': expectedStartTime.toIso8601String(),
          'status': status,
          'raw_status': status.toLowerCase(),
        });
      }
    }

    // 5. Process Unscheduled Walk-ins
    for (var attendance in actualAttendance) {
      if (!claimedAttendanceIds.contains(attendance['id'])) {
        final String dbStatus =
            attendance['status']?.toString().toLowerCase() ?? 'active';
        final bool isOt = attendance['is_overtime'] == true;
        final bool otApproved = attendance['overtime_approved'] == true;

        String rawStatus = dbStatus;
        if (isOt && !otApproved)
          rawStatus = 'overtime_pending';
        else if (dbStatus == 'early_leave_pending')
          rawStatus = 'early_leave_pending';

        finalReport.add({
          'id': attendance['id'],
          'name': attendance['profiles']?['full_name'] ?? 'Unknown Employee',
          'clock_in': attendance['clock_in'],
          'clock_out': attendance['clock_out'],
          'status': dbStatus == 'absent' ? 'Absent' : 'Present',
          'raw_status': rawStatus,
          'overtime_minutes': attendance['overtime_minutes'],
        });
      }
    }

    // Sort descending so the most recent shifts appear at the top
    finalReport.sort((a, b) {
      final timeA = a['expected_start'] ?? a['clock_in'] ?? '0';
      final timeB = b['expected_start'] ?? b['clock_in'] ?? '0';
      return timeB.compareTo(timeA);
    });

    return finalReport;
  }

  // --- EXPENSE CATEGORIES ---

  Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final response = await _supabase
        .from('expenses_category')
        .select()
        .eq('tenant_id', profile['tenant_id'])
        .order('category_name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addExpenseCategory(String categoryName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    await _supabase.from('expenses_category').insert({
      'tenant_id': profile['tenant_id'],
      'category_name': categoryName.trim(),
    });
  }

  Future<void> deleteExpenseCategory(int id) async {
    await _supabase.from('expenses_category').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getCompanyAttendanceByDate(
    DateTime targetDate,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();
    final tenantId = profile['tenant_id'];

    // --- USE THE TARGET DATE INSTEAD OF NOW ---
    final String dateStr =
        "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

    // UTC bounds for fetching actual attendance for the TARGET date
    final startOfDayUtc = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    ).toUtc().toIso8601String();
    final endOfDayUtc = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      23,
      59,
      59,
    ).toUtc().toIso8601String();

    // 1. Fetch SCHEDULED shifts for the TARGET date
    final scheduledRosters = await _supabase
        .from('rosters')
        .select('''
        profile_id,
        profiles!inner(full_name),
        shift_templates!inner(start_time)
      ''')
        .eq('tenant_id', tenantId)
        .eq('shift_date', dateStr);

    // 2. Fetch ACTUAL clock-ins for the TARGET date (The '*' grabs your new booleans!)
    final actualAttendance = await _supabase
        .from('attendance')
        .select('*, profiles!profile_id(full_name)')
        .eq('tenant_id', tenantId)
        .gte('clock_in', startOfDayUtc)
        .lte('clock_in', endOfDayUtc);

    // Sort schedules so morning shifts are processed before afternoon shifts
    (scheduledRosters as List).sort((a, b) {
      final t1 = a['shift_templates']?['start_time'] ?? '00:00:00';
      final t2 = b['shift_templates']?['start_time'] ?? '00:00:00';
      return t1.compareTo(t2);
    });

    // Sort actual clock-ins chronologically
    (actualAttendance as List).sort((a, b) {
      return a['clock_in'].compareTo(b['clock_in']);
    });

    List<Map<String, dynamic>> finalReport = [];
    Set<String> claimedAttendanceIds = {};
    DateTime currentRealTime = DateTime.now();

    // 3. Process everyone who is SCHEDULED
    for (var roster in scheduledRosters) {
      final profileId = roster['profile_id'];
      final employeeName =
          roster['profiles']?['full_name'] ?? 'Unknown Employee';
      final String startTimeStr =
          roster['shift_templates']?['start_time'] ?? '00:00:00';

      final List<String> timeParts = startTimeStr.split(':');
      int hours = int.tryParse(timeParts[0]) ?? 0;
      int minutes = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

      final expectedStartTime = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        hours,
        minutes,
      );

      Map<String, dynamic>? matchedRecord;
      for (var record in actualAttendance) {
        if (record['profile_id'] == profileId &&
            !claimedAttendanceIds.contains(record['id'])) {
          matchedRecord = record;
          break;
        }
      }

      if (matchedRecord != null) {
        claimedAttendanceIds.add(matchedRecord['id']);

        // 1. Calculate lateness
        final actualClockIn = DateTime.parse(
          matchedRecord['clock_in'],
        ).toLocal();
        final minutesLate = actualClockIn
            .difference(expectedStartTime)
            .inMinutes;
        final bool isLate = minutesLate > 0;

        // 2. Extract DB Statuses & Booleans from your schema
        final String dbStatus =
            matchedRecord['status']?.toString().toLowerCase() ?? 'active';
        final bool isOt = matchedRecord['is_overtime'] == true;
        final bool otApproved = matchedRecord['overtime_approved'] == true;
        final bool earlyLeaveApproved =
            matchedRecord['early_leave_approved'] == true;

        // 3. Determine 'raw_status' for the UI Filters (Overtime, Early Leave)
        String rawStatus = dbStatus;
        if (isOt && !otApproved) {
          rawStatus = 'overtime_pending';
        } else if (dbStatus == 'early_leave_pending' && !earlyLeaveApproved) {
          rawStatus = 'early_leave_pending';
        }

        // 4. Determine strict 'status' for the UI Summary Counters (MUST be Present, Late, or Absent)
        String displayStatus;
        if (dbStatus == 'absent') {
          displayStatus = 'Absent';
        } else {
          displayStatus = isLate ? 'Late' : 'Present';
        }

        finalReport.add({
          'id': matchedRecord['id'],
          'name': employeeName,
          'clock_in': matchedRecord['clock_in'],
          'clock_out': matchedRecord['clock_out'],
          'status':
              displayStatus, // 🚀 Perfectly feeds the top summary counters
          'raw_status':
              rawStatus, // 🚀 Perfectly feeds the filter pills and UI badges
          'is_late': isLate,
          'expected_start': expectedStartTime.toIso8601String(),
          'overtime_minutes': matchedRecord['overtime_minutes'],
        });
      } else {
        String status = currentRealTime.isAfter(expectedStartTime)
            ? 'Absent'
            : 'Upcoming';
        finalReport.add({
          'name': employeeName,
          'clock_in': null,
          'clock_out': null,
          'expected_start': expectedStartTime.toIso8601String(),
          'status': status,
          'raw_status': status.toLowerCase(),
        });
      }
    }

    // 4. Process Walk-ins (Ensuring they also get checked for Overtime!)
    for (var attendance in actualAttendance) {
      if (!claimedAttendanceIds.contains(attendance['id'])) {
        final String dbStatus =
            attendance['status']?.toString().toLowerCase() ?? 'active';
        final bool isOt = attendance['is_overtime'] == true;
        final bool otApproved = attendance['overtime_approved'] == true;

        String rawStatus = dbStatus;
        if (isOt && !otApproved) {
          rawStatus = 'overtime_pending';
        } else if (dbStatus == 'early_leave_pending') {
          rawStatus = 'early_leave_pending';
        }

        finalReport.add({
          'id': attendance['id'],
          'name': attendance['profiles']?['full_name'] ?? 'Unknown Employee',
          'clock_in': attendance['clock_in'],
          'clock_out': attendance['clock_out'],
          'status': dbStatus == 'absent' ? 'Absent' : 'Present',
          'raw_status': rawStatus,
          'overtime_minutes': attendance['overtime_minutes'],
        });
      }
    }

    return finalReport;
  }

  // ==========================================
  // RESOLVE EARLY LEAVE (MANAGER)
  // ==========================================

  /// Resolves an early departure alert.
  /// [isApproved] = true: Sets status to 'early_leave_approved', keeps ull minutes.
  /// [isApproved] = false: Sets status to 'early_leave_rejected', recalculates minutes to departure time.
  Future<void> resolveOvertime({
    required String attendanceId,
    required bool approve,
  }) async {
    // If rejected, the overtime_minutes are wiped to 0 so they aren't paid.
    // We don't need to pass current minutes because we only change them on rejection.
    final Map<String, dynamic> updates = {
      'overtime_approved': approve,
      'status': 'completed',
    };

    if (!approve) {
      updates['overtime_minutes'] = 0;
    }

    await _supabase.from('attendance').update(updates).eq('id', attendanceId);
  }

  Future<void> resolveEarlyLeave({
    required String attendanceId,
    required bool isApproved,
  }) async {
    await _supabase
        .from('attendance')
        .update({'early_leave_approved': isApproved, 'status': 'completed'})
        .eq('id', attendanceId);
  }

  // 2. Approve or Reject the Request
  // ==========================================
  // UPDATE LEAVE STATUS & LEDGER ACCRUALS
  // ==========================================
  // ==========================================
  // UPDATE LEAVE STATUS & LEDGER ACCRUALS
  // ==========================================
  // ==========================================
  // UPDATE LEAVE STATUS & LEDGER ACCRUALS (WITH DEBUGGING)
  // ==========================================
  Future<void> updateLeaveStatus(String requestId, String newStatus) async {
    final String cleanStatus = newStatus.toLowerCase().trim();

    print("--- DEBUG: STARTING LEAVE APPROVAL ---");
    print("1. Updating status to: $cleanStatus");

    // 1. Update the leave request status column text
    await _supabase
        .from('leave_requests')
        .update({'status': cleanStatus})
        .eq('id', requestId);

    String? empIdToNotify;
    String? leaveTypeToNotify;

    // 2. Execute ledger adjustments only on a clean approval pass
    if (cleanStatus == 'approved') {
      try {
        final managerId = _supabase.auth.currentUser!.id;
        final managerData = await _supabase
            .from('profiles')
            .select('tenant_id')
            .eq('id', managerId)
            .single();
        final String tenantId = managerData['tenant_id'];

        print("2. Manager Tenant ID verified: $tenantId");

        // Pull metadata details directly from the selected request
        final requestData = await _supabase
            .from('leave_requests')
            .select('profile_id, leave_type, total_days, start_date')
            .eq('id', requestId)
            .single();

        final String empId = requestData['profile_id'];
        final String leaveType = requestData['leave_type'];
        empIdToNotify = empId;
        leaveTypeToNotify = leaveType;

        // 🚨 SUSPECT #1: Is totalDays actually 0?
        final double requestedDays =
            (requestData['total_days'] as num?)?.toDouble() ?? 0.0;
        final int calendarYear = DateTime.parse(requestData['start_date']).year;

        print(
          "3. Request Data Extracted -> EmpID: $empId | Type: $leaveType | Days Requested: $requestedDays | Year: $calendarYear",
        );

        if (requestedDays == 0.0) {
          print(
            "🚨 WARNING: The total_days on this request is 0! The math will not increment anything.",
          );
        }

        // Locate an active baseline profile balance tracker footprint for the year
        final existingBalanceList = await _supabase
            .from('leave_balances')
            .select('id, used_days')
            .eq('profile_id', empId)
            .eq('leave_type', leaveType)
            .eq('year', calendarYear);

        print("4. Found existing balance rows: ${existingBalanceList.length}");

        if (existingBalanceList.isNotEmpty) {
          final existingBalance = existingBalanceList.first;
          final double currentUsed =
              (existingBalance['used_days'] as num?)?.toDouble() ?? 0.0;

          print(
            "5a. UPDATING existing row. Current Used: $currentUsed. Adding: $requestedDays",
          );

          await _supabase
              .from('leave_balances')
              .update({'used_days': currentUsed + requestedDays})
              .eq('id', existingBalance['id']);

          print("✅ UPDATE SUCCESSFUL");
        } else {
          print(
            "5b. NO EXISTING ROW FOUND. Fetching company policy for: $leaveType",
          );

          final policyList = await _supabase
              .from('leave_policies')
              .select('entitled_days')
              .eq('tenant_id', tenantId)
              .eq('leave_type', leaveType);

          final double maxAllowed = policyList.isNotEmpty
              ? (policyList.first['entitled_days'] as num).toDouble()
              : 15.0;

          print(
            "6. Creating NEW balance row with Max Allowed: $maxAllowed and Used Days: $requestedDays",
          );

          await _supabase.from('leave_balances').insert({
            'profile_id': empId,
            'leave_type': leaveType,
            'entitled_days': maxAllowed,
            'used_days': requestedDays,
            'year': calendarYear,
          });

          print("✅ INSERT SUCCESSFUL");
        }
      } catch (e) {
        print("🚨 CRITICAL ERROR DURING MATH EXECUTION: $e");
        throw Exception(
          "Status was approved, but balance update failed. Error: $e",
        );
      }
    } else {
      // If rejected, just grab the details so we can notify them
      final requestData = await _supabase
          .from('leave_requests')
          .select('profile_id, leave_type')
          .eq('id', requestId)
          .single();
      empIdToNotify = requestData['profile_id'];
      leaveTypeToNotify = requestData['leave_type'];
    }

    // 🚀 NOTIFICATION TRIGGER: Tell the Employee
    if (empIdToNotify != null) {
      await sendNotification(
        recipientId: empIdToNotify,
        title: "Leave Request Update",
        message: "Your request for $leaveTypeToNotify has been $cleanStatus.",
      );
    }
  }

  // 2. Clock In
  // ==========================================
  // CLOCK IN
  // ==========================================
  // ==========================================
  // CLOCK IN (Split-Shift Supported)
  // ==========================================
  Future<Map<String, dynamic>> clockIn({
    required String branchId,
    required double lat,
    required double lng,
  }) async {
    final result = await _supabase.rpc(
      'clock_in_v2',
      params: {'p_branch_id': branchId, 'p_lat': lat, 'p_lng': lng},
    );

    final data = Map<String, dynamic>.from(result as Map);

    // The late notification still goes out from here so your existing
    // notifyBusinessOwner helper keeps working — but the *decision* about
    // whether it's late was made by the server, not by this device.
    if (data['is_late'] == true) {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final empProfile = await _supabase
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .single();

        await notifyBusinessOwner(
          title: "Late Clock-In",
          message: "${empProfile['full_name']} clocked in late.",
        );
      }
    }

    return data;
  }

  // ==========================================
  // MANAGER: PAYROLL & TIMESHEET REPORT
  // ==========================================

  Future<List<Map<String, dynamic>>> getTimesheetReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final startString = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    ).toUtc().toIso8601String();
    final endString = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    ).toUtc().toIso8601String();

    final data = await _supabase
        .from('attendance')
        .select('''
          *,
          profiles!profile_id (full_name, avatar_url) 
        ''')
        .eq('tenant_id', profile['tenant_id'])
        .not('clock_out', 'is', null)
        .gte('clock_in', startString)
        .lte('clock_in', endString)
        .order('clock_in', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ==========================================
  // MANAGER: INDIVIDUAL PAYSLIP DETAILS
  // ==========================================

  // In supabase_service.dart
  Future<List<Map<String, dynamic>>> getIndividualPayslipDetails({
    required String profileId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // 🚀 Ensure we cover the full start day and full end day in UTC
    final String start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      0,
      0,
      0,
    ).toUtc().toIso8601String();
    final String end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    ).toUtc().toIso8601String();

    print("Fetching for ID: $profileId");
    print("Date Range: $start to $end");

    // final data = await _supabase
    //     .from('payslip_items')
    //     .select('*')
    //     .eq('profile_id', profileId)
    //     .gte('created_at', start)
    //     .lte('created_at', end)
    //     .order('created_at', ascending: false);

    final data = await _supabase
        .from('payslip_items')
        .select('*')
        .eq('profile_id', profileId);

    return List<Map<String, dynamic>>.from(data);
  }

  // 3. Clock Out
  // Inside your SupabaseService class
  // ==========================================
  // CLOCK OUT
  // ==========================================
  // ==========================================
  // CLOCK OUT (Time-Aware Version)
  // ==========================================
  /// Clock out. The server measures the time, computes the split, and
  /// decides overtime vs early leave. Returns:
  ///   total_minutes, standard_minutes, overtime_minutes,
  ///   status, is_overtime, is_early_leave, server_now
  Future<Map<String, dynamic>> clockOut({
    required String attendanceId,
    required double outLat,
    required double outLng,
  }) async {
    final result = await _supabase.rpc(
      'clock_out_v2',
      params: {
        'p_attendance_id': attendanceId,
        'p_lat': outLat,
        'p_lng': outLng,
      },
    );

    final data = Map<String, dynamic>.from(result as Map);

    // Early departure alert. The decision was made by the server against
    // its own clock — this just delivers the message.
    if (data['is_early_leave'] == true) {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final empProfile = await _supabase
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .single();

        await notifyBusinessOwner(
          title: "Early Departure",
          message: "${empProfile['full_name']} clocked out early.",
        );
      }
    }

    return data;
  }
  // --- Add this to your SupabaseService class ---

  // --- Add to your SupabaseService class ---

  Future<List<Map<String, dynamic>>> getShiftTemplates() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return [];

    // We only get templates that belong to this manager's tenant
    // (Assuming your profiles table stores the tenant_id)
    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', currentUser.id)
        .single();

    final response = await _supabase
        .from('shift_templates')
        .select('*')
        .eq('tenant_id', profile['tenant_id'])
        .order('start_time', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateShiftTemplate({
    required String id,
    required String shiftName,
    required String startTime,
    required String endTime,
    required String colorHex, // Added this
  }) async {
    await _supabase
        .from('shift_templates')
        .update({
          'shift_name': shiftName,
          'start_time': startTime,
          'end_time': endTime,
          'color_hex': colorHex, // Added this
        })
        .eq('id', id);
  }

  Future<void> deleteShiftTemplate(String id) async {
    await _supabase.from('shift_templates').delete().eq('id', id);
  }

  Future<void> createShiftTemplate({
    required String shiftName,
    required String startTime, // Expected format: 'HH:mm:ss'
    required String endTime, // Expected format: 'HH:mm:ss'
    String colorHex = '#00A36C',
  }) async {
    // 1. Get the current manager's tenant_id
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception("User not authenticated");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', currentUser.id)
        .single();

    // 2. Insert the new template
    await _supabase.from('shift_templates').insert({
      'tenant_id': profile['tenant_id'],
      'shift_name': shiftName,
      'start_time': startTime,
      'end_time': endTime,
      'color_hex': colorHex,
    });
  }

  // 2. Get all branches to populate the location dropdown
  // 2. Get all branches belonging to the logged-in user's tenant context
  Future<List<Map<String, dynamic>>> getBranches() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    // 1. Get the manager's tenant_id context securely
    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    // 2. Limit the query to only match their company's tenant ID
    final response = await _supabase
        .from('branches')
        .select('id, name')
        .eq('tenant_id', profile['tenant_id'])
        .order('name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // 3. Save the new shift to the database
  Future<void> createShift({
    required String profileId,
    required String branchId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    // Get the manager's tenant_id to attach to the roster
    final managerProfile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', _supabase.auth.currentUser!.id)
        .single();

    await _supabase.from('rosters').insert({
      'tenant_id': managerProfile['tenant_id'],
      'profile_id': profileId,
      'branch_id': branchId,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'status': 'scheduled',
    });
  }

  Future<void> assignBulkShifts({
    required List<String> employeeIds,
    required String branchId,
    required String templateId,
    required List<DateTime> dates,
  }) async {
    final currentUser = _supabase.auth.currentUser;

    // 1. Get the tenant_id
    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', currentUser!.id)
        .single();

    final List<Map<String, dynamic>> inserts = [];

    // 2. Build the list of all rows to insert
    for (var employeeId in employeeIds) {
      for (var date in dates) {
        final dateStr =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        inserts.add({
          'tenant_id': profile['tenant_id'],
          'profile_id': employeeId,
          'branch_id': branchId,
          'shift_template_id': templateId,
          'shift_date': dateStr,
          'status': 'scheduled',
        });
      }
    }

    // 3. Single database call for all rows
    if (inserts.isNotEmpty) {
      await _supabase.from('rosters').insert(inserts);

      // 🚀 NOTIFICATION TRIGGER: Tell the Employees
      for (var employeeId in employeeIds) {
        await sendNotification(
          recipientId: employeeId,
          title: "New Shifts Scheduled",
          message: "You have been assigned new shifts. Check your schedule.",
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> getRosterForDate(DateTime date) async {
    final currentUser = _supabase.auth.currentUser;

    // Format date to YYYY-MM-DD
    final String dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    // We fetch assignments and "join" the template data
    final response = await _supabase
        .from('rosters')
        .select('''
        id,
        shift_date,
        shift_templates (
          shift_name,
          start_time,
          end_time,
          color_hex
        )
      ''')
        .eq('shift_date', dateStr)
        .order('shift_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // ==========================================
  // EMPLOYEE: VIEW MY SHIFTS
  // ==========================================

  Future<List<Map<String, dynamic>>> getMyUpcomingShifts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    // Get today's date formatted as YYYY-MM-DD
    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Fetch rosters where the profile_id matches the logged-in user,
    // and the date is today or in the future.
    final response = await _supabase
        .from('rosters')
        .select('''
          id,
          shift_date,
          status,
          branches (name),
          shift_templates (
            shift_name,
            start_time,
            end_time,
            color_hex
          )
        ''')
        .eq('profile_id', user.id)
        .gte('shift_date', dateStr)
        .order('shift_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Stream<List<Map<String, dynamic>>> getRosterStream(DateTime date) {
    final String dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    // This creates a real-time listener on the 'rosters' table
    return _supabase
        .from('rosters')
        .stream(primaryKey: ['id'])
        .eq('shift_date', dateStr)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  // Fetch the explicitly assigned branch for the current employee
  Future<Map<String, dynamic>?> getAssignedBranch() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // 1. Look up the employee's assigned branch ID
    final profile = await _supabase
        .from('profiles')
        .select('branch_id')
        .eq('id', user.id)
        .single();

    if (profile['branch_id'] == null) {
      throw Exception(
        "You have not been assigned to a branch yet. Please contact your manager.",
      );
    }

    // 2. Fetch the specific branch's GPS details
    final branch = await _supabase
        .from('branches')
        .select('*')
        .eq('id', profile['branch_id'])
        .single();
    return branch;
  }

  // ==========================================
  // HRM: AWARDS & SEARCH
  // ==========================================

  // 1. Search employees within the manager's tenant
  Future<List<Map<String, dynamic>>> searchEmployees(String query) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    // Get manager's tenant context
    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final List<Map<String, dynamic>> results = await _supabase
        .from('profiles')
        .select(
          'id, full_name, email, role, tenant_id, branch',
        ) // Add 'branch' if you have that column
        .eq('tenant_id', profile['tenant_id'])
        .ilike('full_name', '%$query%') // Case-insensitive fuzzy search
        .order('full_name', ascending: true)
        .limit(10); // Performance cap

    return results;
  }

  // 2. Save the award to the new user_awards table
  Future<void> saveAward({
    required String recipientProfileId,
    required String awardName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'User not authenticated';

    // 1. Get the current manager's profile to find their tenant_id
    final managerProfile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final String tenantId = managerProfile['tenant_id'];

    // 2. Insert the award
    await _supabase.from('user_awards').insert({
      'tenant_id': tenantId,
      'profile_id': recipientProfileId,
      'assigned_by': user.id,
      'award_name': awardName,
    });

    // 🚀 NOTIFICATION TRIGGER: Tell the Employee
    await sendNotification(
      recipientId: recipientProfileId,
      title: "New Award! 🎉",
      message: "Congratulations! You've been recognized for: $awardName.",
    );
  }

  Future<void> terminateEmployee({
    required String employeeId,
    required String reason,
    String? documentUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw "Unauthorized";

    final manager = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();
    final String tenantId = manager['tenant_id'];

    // 1. Record the termination
    await _supabase.from('terminations').insert({
      'tenant_id': tenantId,
      'profile_id': employeeId,
      'terminated_by': user.id,
      'reason': reason,
      'document_url': documentUrl,
    });

    // 2. Optional: Mark the profile as inactive so they don't show up in rosters
    await _supabase
        .from('profiles')
        .update({'role': 'terminated'})
        .eq('id', employeeId);
  }

  Future<void> transferEmployee({
    required String employeeId,
    required String newBranchName, // Changed from ID to Name
    required String? oldBranchName, // Changed from ID to Name
    required DateTime transferDate,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw "Unauthorized";

    // Get the manager's tenant info
    final manager = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    // 1. Log the transfer history using Strings
    await _supabase.from('transfers').insert({
      'tenant_id': manager['tenant_id'],
      'profile_id': employeeId,
      'from_branch': oldBranchName, // Ensure these columns are TEXT in SQL
      'to_branch': newBranchName, // Ensure these columns are TEXT in SQL
      'transfer_date': transferDate.toIso8601String().split('T')[0],
      'processed_by': user.id,
    });

    // 2. Update the profile 'branch' column (String)
    await _supabase
        .from('profiles')
        .update({
          'branch': newBranchName,
        }) // Updated to match your profiles table column
        .eq('id', employeeId);
  }

  // 1. Issue the warning
  Future<void> issueWarning({
    required String employeeId,
    required String message,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw "Unauthorized";

    final manager = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    await _supabase.from('employee_warnings').insert({
      'tenant_id': manager['tenant_id'],
      'profile_id': employeeId,
      'issued_by': user.id,
      'message': message,
    });

    // 🚀 NOTIFICATION TRIGGER: Tell the Employee
    await sendNotification(
      recipientId: employeeId,
      title: "Official Warning",
      message:
          "An official warning has been issued to your profile. Please review it.",
    );
  }

  // 2. Get warning count for a specific employee
  Future<int> getWarningCount(String employeeId) async {
    try {
      // We select just the 'id' and ask for the count.
      // Using head: true makes it a 'HEAD' request, which is faster
      // because it doesn't return the actual data rows, just the count.
      final response = await _supabase
          .from('employee_warnings')
          .select('id')
          .eq('profile_id', employeeId)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      print("Error fetching warning count: $e");
      return 0;
    }
  }

  // 1. Create an Announcement (Now with Dates!)
  Future<void> createAnnouncement({
    required String title,
    required String content,
    String? branchId,
    bool isPinned = false,
    required String startDate, // Added
    required String endDate, // Added
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null)
      throw Exception("Must be logged in to post announcements.");

    // Fetch the current user's profile to get their tenant_id
    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    await _supabase.from('announcements').insert({
      'tenant_id': profile['tenant_id'],
      'author_id': user.id,
      'branch_id': branchId,
      'title': title,
      'content': content,
      'is_pinned': isPinned,
      'start_date': startDate, // Passed to DB
      'end_date': endDate, // Passed to DB
    });

    // 🚀 NOTIFICATION TRIGGER: Broadcast Announcement
    await sendMassNotification(
      title: "New Announcement: $title",
      message: "A new company announcement has been posted.",
      branchId: branchId,
    );
  }

  // 2. Fetch Announcements (We will upgrade this to a Stream later!)
  Future<List<Map<String, dynamic>>> getAnnouncements(String? branchId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    // Fetch the current user's profile to get their tenant_id
    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    // Start building the base query
    var query = _supabase
        .from('announcements')
        .select('*, author:profiles(first_name, last_name)')
        .eq('tenant_id', profile['tenant_id']);

    // Apply the logical OR properly to check for specific branch OR global notices
    if (branchId != null) {
      query = query.or('branch_id.eq.$branchId,branch_id.is.null');
    }

    // Add the ordering at the very end of the builder chain
    final data = await query
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // Fetch all employees in the manager's company (Fixed Schema)
  Future<List<Map<String, dynamic>>> getTenantEmployees() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    // Get the manager's tenant context
    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    // Fetch profiles using YOUR actual column names
    final data = await _supabase
        .from('profiles')
        .select('id, full_name, role, job_title, branch') // MATCHES YOUR SCHEMA
        .eq('tenant_id', profile['tenant_id'])
        .neq('id', user.id)
        .order('full_name', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  // 2. Update the employee's role AND log the promotion
  Future<void> updateEmployeeRole(
    String employeeId,
    String previousRole,
    String newRole,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Must be logged in to promote staff.");

    // 1. Get the manager's tenant context securely
    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final tenantId = profile['tenant_id'];

    // 2. Insert the historical record into the new promotions table
    await _supabase.from('promotions').insert({
      'tenant_id': tenantId,
      'employee_id': employeeId,
      'promoted_by': user.id,
      'previous_role': previousRole,
      'new_role': newRole,
    });

    // 3. Officially update the user's active profile role
    await _supabase
        .from('profiles')
        .update({'role': newRole})
        .eq('id', employeeId);

    // 🚀 NOTIFICATION TRIGGER: Tell the Employee
    await sendNotification(
      recipientId: employeeId,
      title: "Role Update",
      message: "Your system role has been updated to $newRole.",
    );
  }

  // 1. Create a custom job title
  Future<void> createJobTitle(String titleName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    await _supabase.from('job_titles').insert({
      'tenant_id': profile['tenant_id'],
      'title_name': titleName.trim(),
    });
  }

  // 2. Fetch all custom job titles for the tenant
  Future<List<String>> getJobTitles() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final data = await _supabase
        .from('job_titles')
        .select('title_name')
        .eq('tenant_id', profile['tenant_id'])
        .order('title_name', ascending: true);

    return List<String>.from(data.map((item) => item['title_name']));
  }

  // 4. Update an existing Job Title
  Future<void> updateJobTitle(String oldTitle, String newTitle) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final tenantId = profile['tenant_id'];
    final cleanNewTitle = newTitle.trim();

    // 1. Update the name in the job_titles lookup table
    await _supabase
        .from('job_titles')
        .update({'title_name': cleanNewTitle})
        .eq('tenant_id', tenantId)
        .eq('title_name', oldTitle);

    // 2. Sync the change to any employees currently holding the old title
    await _supabase
        .from('profiles')
        .update({
          'job_title': cleanNewTitle,
        }) // Ensure your column is named 'job_title'
        .eq('tenant_id', tenantId)
        .eq('job_title', oldTitle);
  }

  // Delete an existing Job Title from the company registry
  Future<void> deleteJobTitle(String titleName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Must be logged in to manage roles.");

    // 1. Fetch the logged-in manager's tenant_id context for secure multi-tenancy
    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final tenantId = profile['tenant_id'];

    // 2. Remove the custom title entry from the look-up table
    await _supabase
        .from('job_titles')
        .delete()
        .eq('tenant_id', tenantId)
        .eq('title_name', titleName);

    // 3. Clean up worker records: Reset any employee who currently holds
    // this deleted title back to null (or a blank string) so their profile doesn't point to a ghost role.
    await _supabase
        .from('profiles')
        .update({
          'job_title': null,
        }) // Adjust key name to match your schema's column exactly
        .eq('tenant_id', tenantId)
        .eq('job_title', titleName);
  }
  // ==========================================
  // FINANCIAL / PAYROLL MANAGEMENT
  // ==========================================

  // 1. Save or Update an Employee's Salary Configuration
  // 1. Save or Update an Employee's Salary Configuration
  Future<void> upsertSalaryConfig({
    required String profileId,
    required String payrollType,
    required double baseRate,
    required List<Map<String, dynamic>> structuredDeductions,
    double allowances = 0.0,
    double overtimeMultiplier = 1.5,
    String? taxNumber,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    // A. Save the payroll math to salary_configs (REMOVED tax_number from here)
    await _supabase.from('salary_configs').upsert({
      'profile_id': profileId,
      'tenant_id': profile['tenant_id'],
      'payroll_type': payrollType,
      'pay_type': payrollType.toLowerCase().contains('hourly')
          ? 'hourly'
          : 'monthly',
      'base_rate': baseRate,
      'default_deductions': structuredDeductions,
      'default_allowances': allowances,
      'overtime_multiplier': overtimeMultiplier,
    });

    // B. Save the Tax Number to the profiles table!
    if (taxNumber != null) {
      await _supabase
          .from('profiles')
          .update({'tax_number': taxNumber.trim()})
          .eq('id', profileId);
    }
  }

  // 2. Fetch Employee Payroll Overview
  Future<List<Map<String, dynamic>>> getPayrollOverview() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final response = await _supabase
        .from('profiles')
        .select('''
          id,
          full_name,
          tax_number,
          salary_configs (
            payroll_type,
            base_rate,
            default_deductions,
            default_allowances
          )
        ''')
        .eq('tenant_id', profile['tenant_id'])
        .neq('id', user.id);

    return List<Map<String, dynamic>>.from(
      response.map((emp) {
        Map<String, dynamic>? config;
        final rawConfigs = emp['salary_configs'];

        if (rawConfigs is List && rawConfigs.isNotEmpty) {
          config = rawConfigs[0] as Map<String, dynamic>;
        } else if (rawConfigs is Map) {
          config = rawConfigs as Map<String, dynamic>;
        }

        double gross =
            double.tryParse(config?['base_rate']?.toString() ?? '0') ?? 0.0;
        double allowances =
            double.tryParse(config?['default_allowances']?.toString() ?? '0') ??
            0.0;

        double totalComputedDeductions = 0.0;
        final rawDeductionsList =
            config?['default_deductions'] as List<dynamic>? ?? [];

        for (var d in rawDeductionsList) {
          double val = double.tryParse(d['value']?.toString() ?? '0') ?? 0.0;
          if (d['type'] == 'percentage') {
            totalComputedDeductions += (gross * (val / 100));
          } else {
            totalComputedDeductions += val;
          }
        }

        double netSalary = gross - totalComputedDeductions + allowances;

        return {
          'id': emp['id'],
          'name': emp['full_name'] ?? 'Unknown Employee',
          'payrollType': config?['payroll_type'] ?? 'Unconfigured',
          'grossSalary': gross.toStringAsFixed(2),
          'netSalary': netSalary.toStringAsFixed(2),
          'allowances': allowances,
          'rawDeductions': rawDeductionsList,
          'taxNumber':
              emp['tax_number'] ?? '', // 🚀 GRAB IT FROM THE PROFILE ROOT
        };
      }),
    );
  }

  // 2. Fetch Employee Payroll Overview (For the main SalaryScreen list)

  // Add a manual Bonus or Deduction to an employee's payslip items
  Future<void> addManualPayslipItem({
    required String profileId,
    required String itemName,
    required double amount,
    required bool isDeduction,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    // Inserts the standalone item. (It will be caught by your date-range query later!)
    await _supabase.from('payslip_items').insert({
      'tenant_id': profile['tenant_id'],
      'profile_id': profileId,
      'item_name': itemName,
      'amount': amount,
      'is_deduction': isDeduction,
    });

    // 🚀 NOTIFICATION TRIGGER: Notify Business Owner of deduction
    if (isDeduction) {
      final empProfile = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', profileId)
          .single();
      await notifyBusinessOwner(
        title: "Payslip Deduction Logged",
        message:
            "A deduction of $amount ($itemName) was added to ${empProfile['full_name']}'s payslip.",
      );
    }
  }

  // --- ACCOUNTS MANAGEMENT ---

  // 1. Fetch all accounts for the current company
  Future<List<Map<String, dynamic>>> getAccounts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final response = await _supabase
        .from('accounts')
        .select()
        .eq('tenant_id', profile['tenant_id'])
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // 2. Add a new account
  Future<void> addAccount({
    required String name,
    required String type,
    required double initialBalance,
    String? accountNumber,
    String? branch,
    String? code,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    await _supabase.from('accounts').insert({
      'tenant_id': profile['tenant_id'],
      'name': name,
      'account_type': type,
      'balance': initialBalance,
      'account_number': accountNumber ?? 'N/A',
      'branch': branch ?? 'Main',
      'code': code ?? '000',
    });
  }

  // ==========================================
  // --- PAYEES MANAGEMENT ---
  // ==========================================

  // 1. Fetch all payees
  Future<List<Map<String, dynamic>>> getPayees() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final response = await _supabase
        .from('payees')
        .select()
        .eq('tenant_id', profile['tenant_id'])
        .order('name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addPayee({
    required String name,
    required String bankName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    // 🚀 Insert only the columns that actually exist in your database now
    await _supabase.from('payees').insert({
      'tenant_id': profile['tenant_id'],
      'name': name,
      'bank_name': bankName,
    });
  }

  // 3. Update an existing payee
  // 3. Update an existing payee (Account Number Removed!)
  Future<void> updatePayee({
    required String id,
    required String name,
    required String bankName,
  }) async {
    await _supabase
        .from('payees')
        .update({'name': name, 'bank_name': bankName})
        .eq('id', id);
  }

  // 4. Delete a payee
  Future<void> deletePayee(String id) async {
    await _supabase.from('payees').delete().eq('id', id);
  }

  // ==========================================
  // --- PAYERS MANAGEMENT ---
  // ==========================================

  // 1. Fetch all payers
  Future<List<Map<String, dynamic>>> getPayers() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final response = await _supabase
        .from('payers')
        .select()
        .eq('tenant_id', profile['tenant_id'])
        .order('name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // 2. Add a new payer
  Future<void> addPayer({
    required String name,
    required String bankName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    await _supabase.from('payers').insert({
      'tenant_id': profile['tenant_id'],
      'name': name,
      'bank_name': bankName,
    });
  }

  // 3. Update an existing payer
  Future<void> updatePayer({
    required String id,
    required String name,
    required String bankName,
  }) async {
    await _supabase
        .from('payers')
        .update({'name': name, 'bank_name': bankName})
        .eq('id', id);
  }

  // 4. Delete a payer
  Future<void> deletePayer(String id) async {
    await _supabase.from('payers').delete().eq('id', id);
  }

  // ==========================================
  // --- DEPOSITS MANAGEMENT ---
  // ==========================================

  // 1. Fetch all deposits (Joined with account name!)
  Future<List<Map<String, dynamic>>> getDeposits() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final response = await _supabase
        .from('deposits')
        .select(
          '*, accounts(name)',
        ) // 🚀 Joins the accounts table to get the name
        .eq('tenant_id', profile['tenant_id'])
        .order('deposit_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // 2. Add a new deposit (The DB trigger will automatically update the account balance!)
  Future<void> addDeposit({
    required String accountId,
    required double amount,
    required String date,
    String? notes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    await _supabase.from('deposits').insert({
      'tenant_id': profile['tenant_id'],
      'account_id': accountId,
      'amount': amount,
      'deposit_date': date,
      'notes': (notes == null || notes.trim().isEmpty)
          ? 'Deposit'
          : notes.trim(), // 🚀 Default fallback!
    });
  }

  // ==========================================
  // --- EXPENSES MANAGEMENT ---
  // ==========================================

  // 1. Fetch all expenses (Joined with account name)
  Future<List<Map<String, dynamic>>> getExpenses() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final response = await _supabase
        .from('expenses')
        .select('*, accounts(name)') // Joins the account name
        .eq('tenant_id', profile['tenant_id'])
        .order('expense_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // 2. Add an expense (DB Trigger subtracts from balance automatically!)
  // 🚀 UPDATED: Now accepts 'category' instead of 'payee'
  Future<void> addExpense({
    required String accountId,
    required String category,
    required double amount,
    required String date,
    String? paymentMethod,
    String? ref,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    await _supabase.from('expenses').insert({
      'tenant_id': profile['tenant_id'],
      'profile_id': user.id,
      'account_id': accountId,
      'payee':
          category, // 🚀 FIX: Save the category string into the existing payee column
      'amount': amount,
      'expense_date': date,
      'payment_method': paymentMethod,
      'ref': ref,
      'status': 'Pending',
    });
  }

  // 🚀 NEW: Fetches ALL expenses for the Unified Tab view
  Future<List<Map<String, dynamic>>> getAllTenantExpenses() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final response = await _supabase
        .from('expenses')
        .select('''
          *,
          accounts(name),
          profiles(full_name)
        ''')
        .eq('tenant_id', profile['tenant_id'])
        .order('expense_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // 3. Delete an expense
  Future<void> deleteExpense(String id) async {
    // Note: In strict accounting, you usually reverse an entry instead of deleting,
    // but we'll allow standard deletion here for flexibility.
    await _supabase.from('expenses').delete().eq('id', id);
  }

  // 3. Update an existing expense (Text details only, amount remains locked)
  Future<void> updateExpense({
    required String id,
    required String payee,
    required String date,
    String? paymentMethod,
    String? ref,
  }) async {
    await _supabase
        .from('expenses')
        .update({
          'payee': payee,
          'expense_date': date,
          'payment_method': paymentMethod ?? 'Other',
          'ref': ref ?? '-',
        })
        .eq('id', id);
  }

  // ==========================================
  // --- FINANCIAL TRANSFERS MANAGEMENT ---
  // ==========================================

  // 1. Fetch all transfers
  Future<List<Map<String, dynamic>>> getFinancialTransfers() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final response = await _supabase
        .from('financial_transfers')
        // 🚀 Joins the accounts table TWICE to get both names safely
        .select(
          '*, from_account:accounts!from_account_id(name), to_account:accounts!to_account_id(name)',
        )
        .eq('tenant_id', profile['tenant_id'])
        .order('transfer_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // 2. Add a transfer (Trigger handles the double math!)
  Future<void> addFinancialTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String date,
    String? ref,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    if (fromAccountId == toAccountId)
      throw Exception("Cannot transfer to the same account.");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    await _supabase.from('financial_transfers').insert({
      'tenant_id': profile['tenant_id'],
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'amount': amount,
      'transfer_date': date,
      'ref': ref ?? '-',
    });
  }

  // 3. Update text details only (Strict Ledger Rules)
  Future<void> updateFinancialTransfer({
    required String id,
    required String date,
    String? ref,
  }) async {
    await _supabase
        .from('financial_transfers')
        .update({'transfer_date': date, 'ref': ref ?? '-'})
        .eq('id', id);
  }

  // 4. Delete Transfer (Optional, but here if you need it)
  Future<void> deleteFinancialTransfer(String id) async {
    await _supabase.from('financial_transfers').delete().eq('id', id);
  }

  // ==========================================
  // --- DEPARTMENTS MANAGEMENT ---
  // ==========================================

  // 1. Fetch all departments (joined with branch name)
  Future<List<Map<String, dynamic>>> getDepartments() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final response = await _supabase
        .from('departments')
        .select('*, branches(name)') // 🚀 Pulls the branch name automatically!
        .eq('tenant_id', profile['tenant_id'])
        .order('name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // 2. Add a new department
  Future<void> addDepartment({
    required String name,
    required String code,
    required String branchId,
    String? managerName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    await _supabase.from('departments').insert({
      'tenant_id': profile['tenant_id'],
      'branch_id': branchId,
      'name': name,
      'code': code,
      'manager_name': managerName ?? 'Unassigned',
    });
  }

  // 3. Update department
  Future<void> updateDepartment({
    required String id,
    required String name,
    required String code,
    required String branchId,
    String? managerName,
  }) async {
    await _supabase
        .from('departments')
        .update({
          'name': name,
          'code': code,
          'branch_id': branchId,
          'manager_name': managerName ?? 'Unassigned',
        })
        .eq('id', id);
  }

  // 4. Delete department
  Future<void> deleteDepartment(String id) async {
    await _supabase.from('departments').delete().eq('id', id);
  }

  // ==========================================
  // --- PERFORMANCE METRICS ---
  // ==========================================

  Future<Map<String, dynamic>> getPerformanceDashboard() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();
    final tenantId = profile['tenant_id'];

    // 1. Calculate Average Score
    final reviews = await _supabase
        .from('performance_reviews')
        .select('score')
        .eq('tenant_id', tenantId);

    double avgScore = 0.0;
    if (reviews.isNotEmpty) {
      double totalScore = reviews.fold(
        0.0,
        (sum, item) => sum + (item['score'] as num),
      );
      avgScore = totalScore / reviews.length;
    }

    // 2. Calculate Goals Met Percentage
    final goals = await _supabase
        .from('goals')
        .select('progress, title')
        .eq('tenant_id', tenantId);

    int totalGoals = goals.length;
    int completedGoals = goals
        .where((g) => (g['progress'] as num) >= 1.0)
        .length;
    int goalsMetPercentage = totalGoals > 0
        ? ((completedGoals / totalGoals) * 100).round()
        : 0;

    // 3. Filter Active Goals (Progress < 100%)
    final activeGoals = goals
        .where((g) => (g['progress'] as num) < 1.0)
        .toList();

    return {
      'avgScore': avgScore.toStringAsFixed(1),
      'goalsMetPercentage': '$goalsMetPercentage%',
      'activeGoals': activeGoals,
    };
  }
  // ==========================================
  // --- ADD REVIEWS & GOALS ---
  // ==========================================

  // 1. Fetch team members (Employees & Managers) for the dropdowns
  Future<List<Map<String, dynamic>>> getTeamMembers() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final response = await _supabase
        .from('profiles')
        .select('id, full_name, job_title')
        .eq('tenant_id', profile['tenant_id'])
        .order('full_name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // 2. Add a Goal
  Future<void> addGoal({
    required String title,
    String? employeeId, // Optional: Can be assigned to a specific person
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    await _supabase.from('goals').insert({
      'tenant_id': profile['tenant_id'],
      'title': title,
      'employee_id': employeeId,
      'progress': 0.00, // Starts at 0%
    });
  }

  // 3. Log a Performance Review
  Future<void> addPerformanceReview({
    required String employeeId,
    required double score,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    await _supabase.from('performance_reviews').insert({
      'tenant_id': profile['tenant_id'],
      'employee_id': employeeId,
      'score': score,
      'review_date': DateTime.now().toIso8601String(),
    });
  }

  // ==========================================
  // --- APPRAISALS MANAGEMENT ---
  // ==========================================

  // 1. Fetch all appraisals (Joined with employee name)
  Future<List<Map<String, dynamic>>> getAppraisals() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final response = await _supabase
        .from('appraisals')
        .select('*, employee:profiles!employee_id(full_name)')
        .eq('tenant_id', profile['tenant_id'])
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // 2. Start a New Appraisal (Draft Status)
  Future<void> createAppraisal({
    required String employeeId,
    required String reviewPeriod,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    await _supabase.from('appraisals').insert({
      'tenant_id': profile['tenant_id'],
      'employee_id': employeeId,
      'reviewer_id': user.id, // The manager currently logged in
      'review_period': reviewPeriod,
      'status': 'Draft',
    });
  }
  // ==========================================
  // --- TICKETING MANAGEMENT ---
  // ==========================================

  // 1. Fetch tickets (Joined with employee name)
  Future<List<Map<String, dynamic>>> getTickets() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final response = await _supabase
        .from('tickets')
        .select('*, employee:profiles!employee_id(full_name)')
        .eq('tenant_id', profile['tenant_id'])
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // 2. Upload a file to Supabase Storage
  Future<String?> uploadTicketAttachment(File file, String extension) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Create a unique file path using the timestamp
      final filePath =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _supabase.storage.from('ticket_attachments').upload(filePath, file);

      // Get the public URL to save in the database
      return _supabase.storage
          .from('ticket_attachments')
          .getPublicUrl(filePath);
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  // 3. Create a Ticket
  Future<void> createTicket({
    required String title,
    required String description,
    required String category,
    required String priority,
    String? attachmentUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id, full_name')
        .eq('id', user.id)
        .single();

    await _supabase.from('tickets').insert({
      'tenant_id': profile['tenant_id'],
      'employee_id': user.id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': 'Open',
      'attachment_url': attachmentUrl,
    });

    // 🚀 NOTIFICATION TRIGGER: Tell the Admin
    await notifyBusinessOwner(
      title: "New Ticket ($category)",
      message: "${profile['full_name']} submitted a new ticket: $title.",
    );
  }

  // 4. Update Ticket Status
  Future<void> updateTicketStatus(String ticketId, String newStatus) async {
    await _supabase
        .from('tickets')
        .update({'status': newStatus})
        .eq('id', ticketId);

    // 🚀 NOTIFICATION TRIGGER: Tell the Ticket Creator
    try {
      final ticket = await _supabase
          .from('tickets')
          .select('employee_id, title')
          .eq('id', ticketId)
          .single();
      await sendNotification(
        recipientId: ticket['employee_id'],
        title: "Ticket Update",
        message:
            "Your ticket '${ticket['title']}' is now marked as $newStatus.",
      );
    } catch (e) {
      // Silently fail if fetching ticket info fails
    }
  }

  // 5. Get Current User's Role
  Future<String> getCurrentUserRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'Employee'; // Default fallback

    try {
      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      return profile['role']?.toString() ?? 'Employee';
    } catch (e) {
      return 'Employee';
    }
  }

  // ==========================================
  // --- TENANT SETTINGS MANAGEMENT ---
  // ==========================================

  // 1. Fetch current tenant settings
  Future<Map<String, dynamic>?> getTenantSettings() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();
    final tenantId = profile['tenant_id'];

    return await _supabase
        .from('tenants')
        .select('*')
        .eq('id', tenantId)
        .single();
  }

  // 2. Update tenant configuration text fields
  Future<void> updateTenantSettings({
    required String name,
    required String country,
    required String phone,
    required String startTime,
    required String endTime,
    required String currency,
    required String language,
    String? logoUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();
    final tenantId = profile['tenant_id'];

    final updateData = {
      'company_name': name,
      'country': country,
      'company_phone': phone,
      'start_time': startTime,
      'end_time': endTime,
      'currency': currency,
      'language': language,
    };

    if (logoUrl != null) {
      updateData['logo_url'] = logoUrl;
    }

    await _supabase.from('tenants').update(updateData).eq('id', tenantId);
  }

  // 3. Upload Company Logo
  Future<String?> uploadCompanyLogo(File file) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final profile = await _supabase
          .from('profiles')
          .select('tenant_id')
          .eq('id', user.id)
          .single();
      final tenantId = profile['tenant_id'];

      final filePath =
          '$tenantId/logo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage.from('company_logos').upload(filePath, file);
      return _supabase.storage.from('company_logos').getPublicUrl(filePath);
    } catch (e) {
      print("Logo upload error: $e");
      return null;
    }
  }

  // ==========================================
  // --- LEAVE POLICIES MANAGEMENT ---
  // ==========================================

  // 1. Fetch Leave Policies
  Future<List<Map<String, dynamic>>> getLeavePolicies() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final data = await _supabase
        .from('leave_policies')
        .select('*')
        .eq('tenant_id', profile['tenant_id'])
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  // 2. Add a new Leave Policy
  Future<void> addLeavePolicy({
    required String leaveType,
    required int entitledDays,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    await _supabase.from('leave_policies').insert({
      'tenant_id': profile['tenant_id'],
      'leave_type': leaveType.trim(),
      'entitled_days': entitledDays,
    });
  }

  // 3. Update an existing Leave Policy
  Future<void> updateLeavePolicy({
    required String id,
    required String leaveType,
    required int entitledDays,
  }) async {
    await _supabase
        .from('leave_policies')
        .update({'leave_type': leaveType.trim(), 'entitled_days': entitledDays})
        .eq('id', id);
  }

  // 4. Delete a Leave Policy
  Future<void> deleteLeavePolicy(String id) async {
    await _supabase.from('leave_policies').delete().eq('id', id);
  }

  // ==========================================
  // --- EMPLOYEE POLICY-BASED LEAVE FETCH ---
  // ==========================================

  Future<List<Map<String, dynamic>>> getEmployeeLeaveAllowances() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    // 1. Find user tenant ID context
    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();
    final tenantId = profile['tenant_id'];

    // 2. Query available global categories for this workspace
    final policies = await _supabase
        .from('leave_policies')
        .select('leave_type, entitled_days')
        .eq('tenant_id', tenantId)
        .order('leave_type', ascending: true);

    // 3. Gather user's personal spent ledger tracking rows for the current year
    final currentYear = DateTime.now().year;
    final balances = await _supabase
        .from('leave_balances')
        .select('leave_type, entitled_days, used_days')
        .eq('profile_id', user.id)
        .eq('year', currentYear);

    // 4. Merge together safely so every policy shows up, matching customized spent indicators
    List<Map<String, dynamic>> combinedResults = [];

    for (var policy in policies) {
      final String typeName = policy['leave_type'];
      double maxEntitled = (policy['entitled_days'] as num).toDouble();
      double dynamicUsed = 0.0;

      // Check if employee has a personalized overriding row initialized
      final userTrackRow = balances.firstWhere(
        (b) =>
            b['leave_type'].toString().toLowerCase() == typeName.toLowerCase(),
        orElse: () => {},
      );

      if (userTrackRow.isNotEmpty) {
        maxEntitled = (userTrackRow['entitled_days'] as num).toDouble();
        dynamicUsed = (userTrackRow['used_days'] as num?)?.toDouble() ?? 0.0;
      }

      combinedResults.add({
        'leave_type': typeName,
        'entitled_days': maxEntitled,
        'used_days': dynamicUsed,
        'remaining_days': maxEntitled - dynamicUsed,
      });
    }

    return combinedResults;
  }

  // ==========================================
  // --- PERSONAL PROFILE MANAGEMENT ---
  // ==========================================

  // Fetch full profile details for the current user
  Future<Map<String, dynamic>> getCurrentUserProfileDetails() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    return await _supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single();
  }

  // Update personal profile details
  // Update personal profile details
  Future<void> updatePersonalProfile({
    required String fullName,
    String? phoneNum,
    String? address,
    String? email,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");
    final Map<String, dynamic> updateData = {'full_name': fullName};

    if (phoneNum != null && phoneNum.isNotEmpty) {
      // Strips out dashes/spaces and saves strictly as a number
      updateData['phone_num'] = double.tryParse(
        phoneNum.replaceAll(RegExp(r'[^0-9]'), ''),
      );
    }

    if (address != null) updateData['address'] = address;
    if (email != null) updateData['email'] = email;

    await _supabase.from('profiles').update(updateData).eq('id', user.id);
  }
  // ==========================================
  // --- AVATAR UPLOAD MANAGEMENT ---
  // ==========================================

  Future<String?> uploadAvatar(File imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("Not logged in");

      // 1. Create a unique file name using their ID and a timestamp
      final fileExt = imageFile.path.split('.').last;
      final fileName =
          '${user.id}-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      // 2. Upload the file to the 'avatars' bucket
      await _supabase.storage
          .from('avatars')
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // 3. Get the public URL for the newly uploaded image
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      // 4. Update the user's profile row with the new image link
      await _supabase
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', user.id);

      return publicUrl;
    } catch (e) {
      debugPrint("Avatar Upload Error: $e");
      throw Exception("Failed to upload image: $e");
    }
  }

  // ==========================================
  // --- REAL-TIME MESSAGING ENGINE ---
  // ==========================================

  // Get active chat conversations for the logged-in user
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('chat_rooms')
          .select('''
          id,
          updated_at,
          user_one_profile:profiles!chat_rooms_user_one_fkey(id, full_name, avatar_url, job_title, public_key),
          user_two_profile:profiles!chat_rooms_user_two_fkey(id, full_name, avatar_url, job_title, public_key)
        ''')
          .or('user_one.eq.${user.id},user_two.eq.${user.id}')
          .order('updated_at', ascending: false);

      final myKeyPair = await KeyService.loadKeyPair();
      final List<Map<String, dynamic>> conversations = [];

      for (var room in response) {
        final isUserOne = room['user_one_profile']['id'] == user.id;
        final recipientProfile = isUserOne
            ? room['user_two_profile']
            : room['user_one_profile'];

        final latestMsgRes = await _supabase
            .from('chat_messages')
            .select('message_text, created_at, is_read, sender_id')
            .eq('room_id', room['id'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        String previewText = 'Tap to start chatting!';
        if (latestMsgRes?['message_text'] != null) {
          final theirPublicKey = recipientProfile['public_key'] as String?;
          if (myKeyPair != null && theirPublicKey != null) {
            try {
              previewText = await ChatCrypto.decryptMessage(
                encryptedBase64: latestMsgRes!['message_text'],
                myKeyPair: myKeyPair,
                theirPublicKeyBase64: theirPublicKey,
              );
            } catch (_) {
              previewText = '🔒 Encrypted message';
            }
          }
        }

        final unreadCountRes = await _supabase
            .from('chat_messages')
            .select('id')
            .eq('room_id', room['id'])
            .eq('is_read', false)
            .not('sender_id', 'eq', user.id)
            .count(CountOption.exact);

        conversations.add({
          'room_id': room['id'],
          'recipient_id': recipientProfile['id'],
          'name': recipientProfile['full_name'] ?? 'Co-worker',
          'avatar_url': recipientProfile['avatar_url'],
          'job_title': recipientProfile['job_title'] ?? 'Staff',
          'lastMessage': previewText,
          'time': latestMsgRes?['created_at'] != null
              ? DateTime.parse(latestMsgRes!['created_at'])
              : DateTime.parse(room['updated_at']),
          'unreadCount': unreadCountRes.count ?? 0,
        });
      }

      return conversations;
    } catch (e) {
      debugPrint("Conversations Load Error: $e");
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> getLiveMessagesStream(
    String roomId,
  ) async* {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final myKeyPair = await KeyService.loadKeyPair();
    if (myKeyPair == null) return;

    final room = await _supabase
        .from('chat_rooms')
        .select('user_one, user_two')
        .eq('id', roomId)
        .single();
    final recipientId = room['user_one'] == user.id
        ? room['user_two']
        : room['user_one'];
    final recipientProfile = await _supabase
        .from('profiles')
        .select('public_key')
        .eq('id', recipientId)
        .single();
    final theirPublicKey = recipientProfile['public_key'] as String?;

    final rawStream = _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true);

    await for (final rows in rawStream) {
      final decrypted = <Map<String, dynamic>>[];
      for (final row in rows) {
        final copy = Map<String, dynamic>.from(row);
        if (theirPublicKey != null) {
          try {
            copy['message_text'] = await ChatCrypto.decryptMessage(
              encryptedBase64: row['message_text'],
              myKeyPair: myKeyPair,
              theirPublicKeyBase64: theirPublicKey,
            );
          } catch (_) {
            copy['message_text'] = '⚠️ Unable to decrypt';
          }
        }
        decrypted.add(copy);
      }
      yield decrypted;
    }
  }

  // Push a new message to database
  Future<void> sendMessage({
    required String roomId,
    required String text,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final myKeyPair = await KeyService.loadKeyPair();
    if (myKeyPair == null)
      throw Exception('Chat not set up on this device yet');

    final room = await _supabase
        .from('chat_rooms')
        .select('user_one, user_two')
        .eq('id', roomId)
        .single();
    final recipientId = room['user_one'] == user.id
        ? room['user_two']
        : room['user_one'];
    final recipientProfile = await _supabase
        .from('profiles')
        .select('public_key')
        .eq('id', recipientId)
        .single();
    final theirPublicKey = recipientProfile['public_key'] as String?;
    if (theirPublicKey == null)
      throw Exception('This person hasn\'t set up secure chat yet');

    final ciphertext = await ChatCrypto.encryptMessage(
      plaintext: text,
      myKeyPair: myKeyPair,
      theirPublicKeyBase64: theirPublicKey,
    );

    await _supabase.from('chat_messages').insert({
      'room_id': roomId,
      'sender_id': user.id,
      'message_text': ciphertext,
    });
    await _supabase
        .from('chat_rooms')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', roomId);
    // ...notification trigger below stays exactly as-is — it never included message content
  }

  // Clear unread counts upon entering a chat window
  Future<void> markMessagesAsRead(String roomId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('chat_messages')
        .update({'is_read': true})
        .eq('room_id', roomId)
        .not('sender_id', 'eq', user.id);
  }

  // ==========================================
  // --- EMPLOYEE: MY PAYSLIPS ---
  // ==========================================

  // Fetch all payslips generated for the currently logged-in employee
  // ==========================================
  // --- EMPLOYEE: GET MY PAYSLIPS ---
  // ==========================================
  // ==========================================
  // --- EMPLOYEE: MY PAYSLIPS ---
  // ==========================================
  // ==========================================
  // --- EMPLOYEE: MY PAYSLIPS ---
  // ==========================================

  // Fetch all payslips generated for the currently logged-in employee
  Future<List<Map<String, dynamic>>> getMyPayslips() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    // 🚀 ADD THIS LINE TO CHECK YOUR IDENTITY
    debugPrint("🔍 CURRENT LOGGED IN USER ID: ${user.id}");

    final response = await _supabase
        .from('payslips')
        .select('*')
        .eq('profile_id', user.id)
        .order('generated_at', ascending: false);

    // 🚀 ADD THIS TO SEE WHAT SUPABASE FOUND
    debugPrint("🔍 SUPABASE FOUND ${response.length} PAYSLIPS FOR THIS USER");

    return List<Map<String, dynamic>>.from(response);
  }
  // ==========================================
  // --- EMPLOYEE: MY EXPENSE CLAIMS ---
  // ==========================================

  // Fetch expense claims submitted by the current employee
  Future<List<Map<String, dynamic>>> getMyExpenseClaims() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('expense_claims')
          .select('*')
          .eq('profile_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching expenses: $e");
      return [];
    }
  }

  // Submit a new expense claim for Admin approval
  Future<void> submitExpenseClaim({
    required String description,
    required double amount,
    String? receiptUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    // Grab the tenant ID context
    final profile = await _supabase
        .from('profiles')
        .select('tenant_id, full_name')
        .eq('id', user.id)
        .single();

    // Insert into a dedicated claims table
    await _supabase.from('expense_claims').insert({
      'tenant_id': profile['tenant_id'],
      'profile_id': user.id,
      'title': description.trim(),
      'amount': amount,
      'status': 'Pending', // Starts as pending for Admin review
      'claim_date': DateTime.now().toIso8601String().split('T')[0],
      'receipt_url': receiptUrl,
    });

    // 🚀 NOTIFICATION TRIGGER: Notify Business Owner
    await notifyBusinessOwner(
      title: "New Expense Claim",
      message: "${profile['full_name']} submitted a claim for $amount.",
    );
  }

  // ==========================================
  // --- ADMIN: RUN PAYROLL FOR EVERYONE ---
  // ==========================================
  // ==========================================
  // --- ADMIN: RUN PAYROLL FOR EVERYONE ---
  // ==========================================
  Future<void> runMonthlyPayroll(String monthYear) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    // 1. Get Admin's tenant_id
    final admin = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();
    final tenantId = admin['tenant_id'];

    // 2. Figure out the start and end dates for the month
    final parts = monthYear.split(' ');
    final monthsList = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    final monthIndex = monthsList.indexOf(parts[0]) + 1;
    final year = int.parse(parts[1]);

    final startDate = DateTime(year, monthIndex, 1).toUtc().toIso8601String();
    final endDate = DateTime(
      year,
      monthIndex + 1,
      0,
      23,
      59,
      59,
    ).toUtc().toIso8601String();

    // 3. Fetch profiles and configurations
    final employees = await _supabase
        .from('profiles')
        .select(
          'id, salary_configs(base_rate, pay_type, default_allowances, default_deductions)',
        )
        .eq('tenant_id', tenantId);

    // 4. Fetch all completed timesheets for this month
    final attendance = await _supabase
        .from('attendance')
        .select('profile_id, clock_in, clock_out')
        .eq('tenant_id', tenantId)
        .gte('clock_in', startDate)
        .lte('clock_in', endDate)
        .not('clock_out', 'is', null);

    List<Map<String, dynamic>> payslipsToInsert = [];

    // 5. The Math Engine
    for (var emp in employees) {
      if (emp['salary_configs'] == null) continue;

      // 🚀 THE FIX: Safely extract the config whether it's a List or a Map
      final dynamic rawConfigs = emp['salary_configs'];
      Map<String, dynamic>? config;

      if (rawConfigs is List && rawConfigs.isNotEmpty) {
        config = rawConfigs[0] as Map<String, dynamic>;
      } else if (rawConfigs is Map) {
        config = rawConfigs as Map<String, dynamic>;
      }

      // If after checking both it's still null or empty, skip this employee
      if (config == null || config.isEmpty) continue;

      // Now we can safely grab the values
      final isHourly = config['pay_type']?.toString().toLowerCase() == 'hourly';
      final double baseRate =
          double.tryParse(config['base_rate']?.toString() ?? '0') ?? 0.0;
      final double allowances =
          double.tryParse(config['default_allowances']?.toString() ?? '0') ??
          0.0;

      double grossPay = 0.0;

      if (isHourly) {
        int totalMinutes = 0;
        final employeeShifts = attendance.where(
          (a) => a['profile_id'] == emp['id'],
        );

        for (var shift in employeeShifts) {
          final inTime = DateTime.parse(shift['clock_in']).toLocal();
          final outTime = DateTime.parse(shift['clock_out']).toLocal();
          totalMinutes += outTime.difference(inTime).inMinutes;
        }

        if (totalMinutes == 0) continue; // Skip hourly employees with 0 hours

        grossPay = (totalMinutes / 60.0) * baseRate;
      } else {
        grossPay = baseRate;
      }

      // Add their default allowances to the baseline pay
      grossPay += allowances;

      // Calculate dynamic recurring deductions (Tax, Uniform, etc.)
      double computedDeductions = 0.0;
      final rawDeductionsList =
          config['default_deductions'] as List<dynamic>? ?? [];

      for (var rule in rawDeductionsList) {
        double val = double.tryParse(rule['value']?.toString() ?? '0') ?? 0.0;
        if (rule['type'] == 'percentage') {
          computedDeductions += (grossPay * (val / 100));
        } else {
          computedDeductions += val;
        }
      }

      double netPay = grossPay - computedDeductions;

      payslipsToInsert.add({
        'tenant_id': tenantId,
        'profile_id': emp['id'],
        'month_year': monthYear,
        'gross_pay': grossPay,
        'tax': 0.0,
        'deductions': computedDeductions,
        'net_pay': netPay,
        'status': 'Pending',
      });
    }

    if (payslipsToInsert.isEmpty) {
      throw Exception(
        "No active employees with logged hours or salaries found.",
      );
    }

    // 6. Save every payslip to the database
    await _supabase.from('payslips').insert(payslipsToInsert);

    // 🚀 NOTIFICATION TRIGGER: Tell everyone their payslips are ready!
    await sendMassNotification(
      title: "Payslip Generated",
      message: "Your payslip for $monthYear is now available.",
    );
  }

  // ==========================================
  // --- ADMIN: UPDATE PAYSLIP STATUS ---
  // ==========================================
  Future<void> updatePayslipStatus(String payslipId, String newStatus) async {
    await _supabase
        .from('payslips')
        .update({'status': newStatus})
        .eq('id', payslipId);
  }

  Future<void> bulkUpdatePayslipStatus(
    String monthYear,
    String newStatus,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    // 1. Get the Admin's tenant_id to make sure we only update THEIR employees
    final adminProfile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    // 2. Update every payslip for that specific month!
    await _supabase
        .from('payslips')
        .update({'status': newStatus})
        .eq('tenant_id', adminProfile['tenant_id'])
        .eq('month_year', monthYear);
  }

  Future<Map<String, dynamic>?> getLatestPayslipForEmployee(
    String profileId,
  ) async {
    try {
      final response = await _supabase
          .from('payslips')
          .select('*')
          .eq('profile_id', profileId)
          // 🚀 MUST use 'generated_at' here too!
          .order('generated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint("Error loading latest payslip: $e");
      return null;
    }
  }

  // ==========================================
  // --- OFFBOARDING: PROCESS RESIGNATION (WITH UPLOAD) ---
  // ==========================================
  Future<void> processResignation({
    required String employeeId,
    required DateTime resignationDate,
    required String reason,
    // 🚀 NEW: Accept file data
    required dynamic fileBytes, // Using dynamic/Uint8List for Web compatibility
    required String? fileName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    // 1. Get the admin's tenant ID
    final adminProfile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    String? documentUrl;

    // 2. Upload the document to Storage (if one was selected)
    if (fileBytes != null && fileName != null) {
      // Create a unique, organized folder path: tenant_id / employee_id / timestamp_filename
      final filePath =
          '${adminProfile['tenant_id']}/$employeeId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // uploadBinary is crucial because it works flawlessly on both Web and Mobile
      await _supabase.storage
          .from('employee_documents')
          .uploadBinary(filePath, fileBytes);

      // Get the URL so we can save it in the database
      documentUrl = _supabase.storage
          .from('employee_documents')
          .getPublicUrl(filePath);
    }

    // 3. Insert the resignation record with the URL
    await _supabase.from('resignations').insert({
      'tenant_id': adminProfile['tenant_id'],
      'profile_id': employeeId,
      'resignation_date': resignationDate.toIso8601String(),
      'reason': reason,
      'document_url': documentUrl, // 🚀 NEW: Save the URL to the table
      'status': 'Processed',
    });

    // 4. Update the employee's profile status
    await _supabase
        .from('profiles')
        .update({'status': 'Resigned'})
        .eq('id', employeeId);
  }

  // ==========================================
  // --- TRAINING DESIGNATOR METHODS ---
  // ==========================================
  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> createTraining({
    required String tenantId,
    required String adminId,
    required String trainerId,
    required String traineeId,
    required String topic,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
  }) async {
    try {
      await _supabase.from('trainings').insert({
        'tenant_id': tenantId,
        'admin_id': adminId,
        'trainer_id': trainerId,
        'trainee_id': traineeId,
        'topic': topic,
        'description': description,
        'start_date': _dateOnly(startDate),
        'end_date': _dateOnly(endDate),
        'status': 'pending',
      });

      final range = '${_dateOnly(startDate)} to ${_dateOnly(endDate)}';

      await sendNotification(
        recipientId: trainerId,
        title: "Training Scheduled",
        message: "You are training a team member on: $topic ($range).",
      );
      await sendNotification(
        recipientId: traineeId,
        title: "Training Scheduled",
        message: "You have been scheduled for training on: $topic ($range).",
      );
    } catch (e) {
      debugPrint('Error creating training: $e');
      rethrow;
    }
  }

  /// Fetch all trainings for the current company.
  /// Relational selects pull the trainer/trainee/admin names in one round trip.
  Future<List<Map<String, dynamic>>> getCompanyTrainings(
    String tenantId,
  ) async {
    try {
      final response = await _supabase
          .from('trainings')
          .select('''
            *,
            trainer:profiles!trainer_id(full_name, avatar_url),
            trainee:profiles!trainee_id(full_name, avatar_url),
            admin:profiles!admin_id(full_name)
          ''')
          .eq('tenant_id', tenantId)
          .order('start_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching trainings: $e');
      return [];
    }
  }

  Future<void> updateTrainingStatus({
    required String trainingId,
    required String status,
    required String topic,
    String? trainerId,
    String? traineeId,
  }) async {
    try {
      final updates = <String, dynamic>{'status': status};

      if (status == 'completed') {
        updates['completed_at'] = DateTime.now().toUtc().toIso8601String();
      } else {
        // Re-opening a completed training clears the stamp.
        updates['completed_at'] = null;
      }

      await _supabase.from('trainings').update(updates).eq('id', trainingId);

      final message = switch (status) {
        'in_progress' => "Your training on $topic has started.",
        'completed' => "Your training on $topic is marked complete.",
        'cancelled' => "Your training on $topic has been cancelled.",
        _ => "Your training on $topic was updated.",
      };

      for (final id in [trainerId, traineeId]) {
        if (id != null) {
          await sendNotification(
            recipientId: id,
            title: "Training Updated",
            message: message,
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating training status: $e');
      rethrow;
    }
  }

  /// Push a training's end date back. Records the original end date the first
  /// time this happens so the UI can show what it was extended from.
  Future<void> extendTraining({
    required String trainingId,
    required DateTime newEndDate,
    required DateTime currentEndDate,
    DateTime? originalEndDate,
    required String topic,
    String? trainerId,
    String? traineeId,
  }) async {
    try {
      await _supabase
          .from('trainings')
          .update({
            'end_date': _dateOnly(newEndDate),
            'original_end_date': _dateOnly(originalEndDate ?? currentEndDate),
            'status': 'extended',
          })
          .eq('id', trainingId);

      for (final id in [trainerId, traineeId]) {
        if (id != null) {
          await sendNotification(
            recipientId: id,
            title: "Training Extended",
            message:
                "Training on $topic now runs until ${_dateOnly(newEndDate)}.",
          );
        }
      }
    } catch (e) {
      debugPrint('Error extending training: $e');
      rethrow;
    }
  }

  /// Edit the core details of an existing training.
  Future<void> updateTrainingDetails({
    required String trainingId,
    required String topic,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      await _supabase
          .from('trainings')
          .update({
            'topic': topic,
            'description': description,
            'start_date': _dateOnly(startDate),
            'end_date': _dateOnly(endDate),
          })
          .eq('id', trainingId);
    } catch (e) {
      debugPrint('Error updating training: $e');
      rethrow;
    }
  }

  Future<void> deleteTraining(String trainingId) async {
    await _supabase.from('trainings').delete().eq('id', trainingId);
  }
  // ==========================================
  // --- ASSET MANAGEMENT METHODS ---
  // ==========================================

  Future<List<Map<String, dynamic>>> getCompanyAssets(String tenantId) async {
    try {
      final response = await _supabase
          .from('assets')
          .select(
            '*, assigned_to_profile:profiles!assigned_to(full_name, avatar_url)',
          )
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching assets: $e');
      return [];
    }
  }

  Future<void> saveAsset({
    String?
    assetId, // If null, it creates a new asset. If provided, it updates.
    required String tenantId,
    required String name,
    String? description,
    required String status,
    String? assignedTo,
  }) async {
    final payload = {
      'tenant_id': tenantId,
      'name': name,
      'description': description,
      'status': status,
      'assigned_to': assignedTo,
    };

    if (assetId == null) {
      // Create new
      await _supabase.from('assets').insert(payload);
    } else {
      // Update existing
      await _supabase.from('assets').update(payload).eq('id', assetId);
    }

    // 🚀 NOTIFICATION TRIGGER: Tell the Employee they got a new asset
    if (assignedTo != null) {
      await sendNotification(
        recipientId: assignedTo,
        title: "New Equipment Assigned",
        message: "$name has been assigned to your profile.",
      );
    }
  }

  Future<void> deleteAsset(String assetId) async {
    await _supabase.from('assets').delete().eq('id', assetId);
  }
  // ==========================================
  // --- EMPLOYEE APPROVAL METHODS ---
  // ==========================================

  Future<void> updateEmployeeApprovalStatus(
    String employeeId,
    String status,
  ) async {
    try {
      await _supabase
          .from('profiles')
          .update({'approval_status': status})
          .eq('id', employeeId);
    } catch (e) {
      debugPrint('Error updating approval status: $e');
      rethrow;
    }
  }

  // ==========================================
  // --- ROLE CREATION & MANAGEMENT ---
  // ==========================================

  // 1. Fetch the master list of available permissions
  Future<List<Map<String, dynamic>>> getAvailableAppPermissions() async {
    // Note: You can optionally add a filter here later to only fetch
    // permissions that match the user's current subscription tier!
    final data = await _supabase
        .from('app_permissions')
        .select('*')
        .order('module');
    return List<Map<String, dynamic>>.from(data);
  }

  // 2. Fetch all custom roles created by this company
  Future<List<Map<String, dynamic>>> getTenantRoles() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final data = await _supabase
        .from('tenant_roles')
        .select('*, role_permissions(permission_id)')
        .eq('tenant_id', profile['tenant_id'])
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  // 3. Create a new Custom Role and link its permissions
  Future<void> createCustomRole(
    String roleName,
    List<String> permissionIds,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();
    final tenantId = profile['tenant_id'];

    // Step A: Insert the Role
    final roleData = await _supabase
        .from('tenant_roles')
        .insert({'tenant_id': tenantId, 'role_name': roleName.trim()})
        .select('id')
        .single();

    final String newRoleId = roleData['id'];

    // Step B: Insert the Bridge records (Linking the role to the permissions)
    if (permissionIds.isNotEmpty) {
      final List<Map<String, dynamic>> bridges = permissionIds
          .map((permId) => {'role_id': newRoleId, 'permission_id': permId})
          .toList();

      await _supabase.from('role_permissions').insert(bridges);
    }
  }

  // ==========================================
  // --- UNIFIED ROLE & PERMISSION SAVING ---
  // ==========================================
  Future<void> saveRoleWithPermissions({
    String? roleId, // If null, we create a new role. If provided, we update.
    required String roleName,
    required List<String> permissionIds,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final profile = await _supabase
        .from('profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .single();
    final tenantId = profile['tenant_id'];

    String targetRoleId;

    if (roleId == null) {
      // 1A. Create a NEW role
      final roleData = await _supabase
          .from('tenant_roles')
          .insert({'tenant_id': tenantId, 'role_name': roleName.trim()})
          .select('id')
          .single();
      targetRoleId = roleData['id'];
    } else {
      // 1B. Update EXISTING role name
      await _supabase
          .from('tenant_roles')
          .update({'role_name': roleName.trim()})
          .eq('id', roleId);
      targetRoleId = roleId;

      // Wipe old permissions before applying new ones
      await _supabase
          .from('role_permissions')
          .delete()
          .eq('role_id', targetRoleId);
    }

    // 2. Insert the fresh batch of permissions
    if (permissionIds.isNotEmpty) {
      final List<Map<String, dynamic>> bridges = permissionIds
          .map((permId) => {'role_id': targetRoleId, 'permission_id': permId})
          .toList();

      await _supabase.from('role_permissions').insert(bridges);
    }
  }

  // ==========================================
  // --- FETCH USER PERMISSIONS ON LOGIN ---
  // ==========================================
  Future<List<String>> getUserPermissions(
    String? customRoleId,
    String legacyRole,
  ) async {
    // 1. If they have a Custom Role assigned, use its exact permissions!
    // (This allows you to test custom roles even if your account is technically a 'Manager')
    if (customRoleId != null) {
      final data = await _supabase
          .from('role_permissions')
          .select('app_permissions!inner(action_name)')
          .eq('role_id', customRoleId);

      return data
          .map((e) => e['app_permissions']['action_name'] as String)
          .toList();
    }

    // 2. Legacy Fallback: If no custom role is assigned yet, but they are a master 'Manager',
    // download the entire master list of permissions so they aren't locked out of their own app.
    if (legacyRole.toLowerCase() == 'manager') {
      final data = await _supabase
          .from('app_permissions')
          .select('action_name');
      return data.map((e) => e['action_name'] as String).toList();
    }

    // 3. Baseline Employee with no custom role
    return [];
  }

  // Delete a unified role
  Future<void> deleteUnifiedRole(String roleId) async {
    // Because we set ON DELETE CASCADE in SQL, deleting the role
    // automatically deletes all its linked permissions!
    await _supabase.from('tenant_roles').delete().eq('id', roleId);
  }

  // 3. Update an Appraisal (Manager saves score and completes)
  Future<void> updateAppraisal({
    required String appraisalId,
    required double score,
    required String comments,
    required String status,
  }) async {
    await _supabase
        .from('appraisals')
        .update({'score': score, 'comments': comments, 'status': status})
        .eq('id', appraisalId);

    // 🚀 NOTIFICATION TRIGGER: Tell the Employee
    if (status == 'Completed') {
      final data = await _supabase
          .from('appraisals')
          .select('employee_id')
          .eq('id', appraisalId)
          .single();
      await sendNotification(
        recipientId: data['employee_id'],
        title: "Performance Review Completed",
        message:
            "Your manager has finalized your appraisal. Tap to view your score and feedback.",
      );
    }
  }

  // Add this inside supabase_service.dart
  // Add this inside supabase_service.dart
  Future<List<Map<String, dynamic>>> getManagerReport({
    required String tenantId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // 1. Get the raw stats (hours, lates, leave days) from the SQL engine
      final response = await Supabase.instance.client.rpc(
        'generate_manager_report',
        params: {
          'p_tenant_id': tenantId,
          'p_start_date': startDate.toIso8601String().split('T')[0],
          'p_end_date': endDate.toIso8601String().split('T')[0],
        },
      );

      List<Map<String, dynamic>> rawReport = List<Map<String, dynamic>>.from(
        response,
      );

      // 2. 🚀 THE FIX: Fetch profiles WITH their complex salary configurations
      final profilesResponse = await Supabase.instance.client
          .from('profiles')
          .select(
            'id, full_name, salary_configs(base_rate, pay_type, default_allowances, default_deductions)',
          )
          .eq('tenant_id', tenantId);

      final profiles = List<Map<String, dynamic>>.from(profilesResponse);

      // 3. 🚀 THE FIX: Fetch manual payslip adjustments (Bonuses/Deductions) for the date range
      final payslipItemsResponse = await Supabase.instance.client
          .from('payslip_items')
          .select('*')
          .eq('tenant_id', tenantId)
          .gte(
            'created_at',
            DateTime(
              startDate.year,
              startDate.month,
              startDate.day,
            ).toUtc().toIso8601String(),
          )
          .lte(
            'created_at',
            DateTime(
              endDate.year,
              endDate.month,
              endDate.day,
              23,
              59,
              59,
            ).toUtc().toIso8601String(),
          );

      final payslipItems = List<Map<String, dynamic>>.from(
        payslipItemsResponse,
      );

      // 4. Map names and overwrite the Net Pay using the true Payroll Math Engine
      for (var row in rawReport) {
        final profileId = row['profile_id'];
        final match = profiles.firstWhere(
          (p) => p['id'] == profileId,
          orElse: () => {'full_name': 'Unknown User'},
        );

        row['employee_name'] = match['full_name'] ?? 'Unknown User';

        // --- 🚀 THE FINANCIAL MATH ENGINE ---
        double finalNetPay = 0.0;
        final rawConfigs = match['salary_configs'];
        Map<String, dynamic>? config;

        // Safely extract the config whether it's a List or a Map
        if (rawConfigs is List && rawConfigs.isNotEmpty) {
          config = rawConfigs[0] as Map<String, dynamic>;
        } else if (rawConfigs is Map) {
          config = rawConfigs as Map<String, dynamic>;
        }

        if (config != null && config.isNotEmpty) {
          final isHourly =
              config['pay_type']?.toString().toLowerCase() == 'hourly';
          final double baseRate =
              double.tryParse(config['base_rate']?.toString() ?? '0') ?? 0.0;
          final double allowances =
              double.tryParse(
                config['default_allowances']?.toString() ?? '0',
              ) ??
              0.0;

          double grossPay = 0.0;

          if (isHourly) {
            // Leverage the total standard minutes already perfectly tallied by the RPC
            final totalMinutes =
                (row['total_standard_minutes'] as num?)?.toInt() ?? 0;
            grossPay = (totalMinutes / 60.0) * baseRate;
          } else {
            grossPay = baseRate; // Salaried workers get their fixed base rate
          }

          // Add default allowances
          grossPay += allowances;

          // Subtract dynamic recurring deductions (e.g. Tax PAYE)
          double computedDeductions = 0.0;
          final rawDeductionsList =
              config['default_deductions'] as List<dynamic>? ?? [];

          for (var rule in rawDeductionsList) {
            double val =
                double.tryParse(rule['value']?.toString() ?? '0') ?? 0.0;
            if (rule['type'] == 'percentage') {
              computedDeductions += (grossPay * (val / 100));
            } else {
              computedDeductions += val;
            }
          }

          finalNetPay = grossPay - computedDeductions;
        }

        // Apply manual line item adjustments (Bonuses or Penalties logged this month)
        final userItems = payslipItems.where(
          (item) => item['profile_id'] == profileId,
        );
        for (var item in userItems) {
          double amount = (item['amount'] as num).toDouble();
          if (item['is_deduction'] == true) {
            finalNetPay -= amount;
          } else {
            finalNetPay += amount;
          }
        }

        // Ensure payslip doesn't drop into negatives
        if (finalNetPay < 0) finalNetPay = 0.0;

        // Overwrite the inaccurate RPC value with the true calculated Net Pay!
        row['total_net_pay'] = finalNetPay;
      }

      return rawReport;
    } catch (e) {
      print('Error fetching report: $e');
      throw Exception('Failed to load report data');
    }
  }

  // ============================================================
  // Add to supabase_service.dart, near the login / signUp methods.
  // ============================================================

  /// Does this account still need to set its own password?
  /// Call after login to decide whether to route into the forced flow.
  Future<bool> needsPasswordChange() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final data = await _supabase
        .from('profiles')
        .select('must_change_password')
        .eq('id', user.id)
        .maybeSingle();

    return data?['must_change_password'] == true;
  }

  /// Change the signed-in user's password.
  ///
  /// Supabase's updateUser does NOT verify the current password, so we
  /// re-authenticate first. That serves two purposes: it proves the person
  /// at the keyboard knows the existing password, and it gives us the old
  /// password in hand — which the chat key re-wrap needs (see below).
  ///
  /// Throws a human-readable Exception on failure.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('You are not signed in.');

    final email = user.email;
    if (email == null) {
      throw Exception('This account has no email address on file.');
    }

    if (newPassword.trim().length < 8) {
      throw Exception('Your new password needs at least 8 characters.');
    }
    if (newPassword.trim() == currentPassword.trim()) {
      throw Exception(
        'Your new password must be different from the current one.',
      );
    }

    // 1. Prove they know the current password.
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword.trim(),
      );
    } on AuthException {
      throw Exception('That current password is not correct.');
    }

    // 2. ⚠️ CHAT KEY RE-WRAP GOES HERE — BEFORE the password changes.
    //
    // signInUser() derives the chat identity from the login password via
    // KeyService.restoreFromPassword(). If the password changes without the
    // key material being re-wrapped under the new one, the user permanently
    // loses access to their encrypted chat history.
    //
    // Uncomment and adjust once the KeyService API is confirmed:

    await KeyService.rewrapOnPasswordChange(
      user.id,
      currentPassword.trim(),
      newPassword.trim(),
    );
    //
    // If it throws, we must NOT proceed to step 3 — better to fail the
    // password change than to silently orphan the keys.

    // 3. Set the new password.
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword.trim()),
    );

    // 4. Clear the first-login flag.
    await _supabase
        .from('profiles')
        .update({'must_change_password': false})
        .eq('id', user.id);
  }
}
