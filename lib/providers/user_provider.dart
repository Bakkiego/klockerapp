import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- Need this for Realtime
import 'package:klockerapp/models/app_enums.dart';

class UserProvider with ChangeNotifier {
  userRole? _role;
  String? _tenantId;
  String? _subscriptionTier;
  String? _fullName;
  String? _companyName;

  // 🚀 1. NEW: The permissions list
  List<String> _permissions = [];

  // This variable holds our database "listener"
  RealtimeChannel? _tenantSubscription;

  // Getters
  userRole? get role => _role;
  String? get tenantId => _tenantId;
  String? get subscriptionTier => _subscriptionTier;
  String? get fullName => _fullName;
  String? get companyName => _companyName;

  // 🚀 2. NEW: Permissions Getter & UI Gatekeeper
  List<String> get permissions => _permissions;

  /// The magical 'can' function that controls what buttons the user sees
  bool can(String actionName) {
    if (role == userRole.Manager) {
      return true;
    }

    // Otherwise, check if their assigned Custom Role has the specific key
    return _permissions.contains(actionName);
  }

  String? _avatarUrl;
  String? get avatarUrl => _avatarUrl;

  String _currencySymbol = 'R'; // Default to ZAR symbol
  String get currencySymbol => _currencySymbol;

  void setUserProfile(Map<String, dynamic> userData) {
    _role = userRole.fromString(userData['role']);
    _tenantId = userData['tenant_id'];
    _fullName = userData['full_name'];
    _subscriptionTier = userData['tenants']?['subscription_tier'] ?? 'lite';

    // Safely extract the company name
    _companyName = userData['company_name'] ?? userData['tenants']?['name'];

    _avatarUrl = userData['avatar_url'];
    notifyListeners();

    // Start listening for instant upgrades the moment they open the app!
    if (_tenantId != null) {
      _listenForPlanUpgrades(_tenantId!);
    }
  }

  // 🚀 3. NEW: Load the permissions in from the database
  void setPermissions(List<String> perms) {
    _permissions = perms;
    notifyListeners();
  }

  // Updates the name and instantly refreshes any screen listening to it
  void setFullName(String name) {
    _fullName = name;
    notifyListeners();
  }

  // Instant manual update for settings screen
  void setCompanyName(String name) {
    _companyName = name;
    notifyListeners();
  }

  void setAvatarUrl(String url) {
    _avatarUrl = url;
    notifyListeners();
  }

  void setCurrencySymbol(String symbol) {
    _currencySymbol = symbol;
    notifyListeners();
  }

  // --- THE REALTIME MAGIC ---
  void _listenForPlanUpgrades(String tenantId) {
    _tenantSubscription?.unsubscribe();

    _tenantSubscription = Supabase.instance.client
        .channel('public:tenants')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'tenants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: tenantId,
          ),
          callback: (payload) {
            final newTier = payload.newRecord['subscription_tier'];
            final newName = payload.newRecord['name'];

            bool wasUpdated = false;

            if (newTier != null && newTier != _subscriptionTier) {
              _subscriptionTier = newTier;
              wasUpdated = true;
            }

            if (newName != null && newName != _companyName) {
              _companyName = newName;
              wasUpdated = true;
            }

            if (wasUpdated) {
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  void clear() {
    // Turn off the listener when they log out
    _tenantSubscription?.unsubscribe();
    _avatarUrl = null;
    _role = null;
    _tenantId = null;
    _subscriptionTier = null;
    _fullName = null;
    _companyName = null;

    // 🚀 4. NEW: Wipe the permissions out on logout for security
    _permissions = [];

    notifyListeners();
  }
}
