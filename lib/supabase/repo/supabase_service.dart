import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_enums.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

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
        .select('*, tenants(name)')
        .eq('id', userId)
        .single();

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
  Future<void> signUpAdmin({
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
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<Map<String, dynamic>> signInUser(String email, String password) async {
    //login to supabase
    final AuthResponse res = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final user = res.user;
    if (user == null) throw "Sign in failed - No user returned";

    //get the user's profile
    final data = await _supabase
        .from('profiles')
        .select('*, tenants(name)')
        .eq('id', user.id)
        .single();
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
}
