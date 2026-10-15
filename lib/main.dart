import 'package:flutter/material.dart';
import 'package:klockerapp/screens/theme_preview_screen.dart';
import 'package:klockerapp/utils/custom_theme/k_theme.dart';
import 'package:klockerapp/screens/login_screen.dart';
import 'package:klockerapp/components/bottom_nav.dart';
import 'package:klockerapp/supabase/supabase_config.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/app_enums.dart';
import 'package:provider/provider.dart';
import 'package:klockerapp/providers/user_provider.dart';
import 'package:klockerapp/supabase/google_calendar_service.dart';
import 'package:klockerapp/screens/pending_approval_screen.dart';
import 'package:klockerapp/screens/subscription_locked_screen.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

// 🚀 Required for detecting platform and launching URLs
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await dotenv.load(fileName: "config.env");
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUri,
    anonKey: SupabaseConfig.supabaseAnon,
  );

  // Wrap the entire app in the Provider
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static final themeMode = ValueNotifier(ThemeMode.system);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeMode,
      builder: (context, mode, _) {
        final session = Supabase.instance.client.auth.currentSession;
        return MaterialApp(
          title: 'KlockerApp',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: KTheme.light,
          darkTheme: KTheme.dark,
          routes: {'/theme': (_) => const ThemePreviewScreen()},
          home: session != null
              ? AuthGate(userId: session.user.id)
              : const LoginScreen(),
        );
      },
    );
  }
}

// Changed to StatefulWidget to safely load data into the Provider
class AuthGate extends StatefulWidget {
  final String userId;
  const AuthGate({super.key, required this.userId});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  userRole? _role;
  String? _approvalStatus;

  // 🚀 Subscription gate. This is the path EVERY returning user takes —
  // Supabase restores the session on launch, so the login screen is never
  // built for them and any check living there can't gate anything.
  bool _tenantActive = true;
  Map<String, dynamic>? _billingState;

  // Set when the profile load itself failed, so we can tell "couldn't
  // reach the server" apart from "you're not allowed in".
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _wakeUpGoogleServices() async {
    await GoogleCalendarService().restoreSession();
  }

  Future<void> _loadProfileData() async {
    try {
      final data = await SupabaseService().getUserProfile(widget.userId);

      // Check billing before doing any more work. A lapsed tenant's other
      // reads are refused by RLS anyway, so loading permissions and tenant
      // settings would just produce noise in the logs.
      final billing = await SupabaseService().getBillingState();
      final isActive = billing?['is_active'] == true;

      if (!mounted) return;

      if (!isActive) {
        setState(() {
          _billingState = billing;
          _tenantActive = false;
          _approvalStatus = data['approval_status'] ?? 'approved';
          _isLoading = false;
        });
        return;
      }

      context.read<UserProvider>().setUserProfile(data);

      // Fetch and set permissions silently on app start
      final String legacyRole = data['role'] ?? 'employee';
      final String? customRoleId = data['custom_role_id'];

      final permissions = await SupabaseService().getUserPermissions(
        customRoleId,
        legacyRole,
      );
      if (!mounted) return;
      context.read<UserProvider>().setPermissions(permissions);

      final tenantSettings = await SupabaseService().getTenantSettings();
      if (!mounted) return;
      if (tenantSettings?['currency'] != null) {
        context.read<UserProvider>().setCurrencyFromCode(
          tenantSettings!['currency'],
        );
      }

      setState(() {
        _role = userRole.fromString(legacyRole);
        _approvalStatus = data['approval_status'] ?? 'approved';
        _tenantActive = true;
        _isLoading = false;
      });
    } on PostgrestException catch (e) {
      // See isTenantActive() — if the RPC isn't deployed yet, don't lock
      // the whole customer base out.
      debugPrint("AuthGate Error: ${e.code} ${e.message}");
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _tenantActive = e.code == 'PGRST202' || e.code == '42883';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("AuthGate Error: $e");
      if (mounted) {
        setState(() {
          _loadFailed = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // The Security Locks
    if (_approvalStatus == 'rejected') {
      // Safely force a sign-out in the background and boot them to Login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Supabase.instance.client.auth.signOut();
      });
      return const LoginScreen();
    }

    if (_approvalStatus == 'pending') {
      return const PendingApprovalScreen();
    }

    // 🚀 Subscription gate. Nothing is deleted — this screen re-checks and
    // lets them back in as soon as the payment lands.
    if (!_tenantActive) {
      return SubscriptionLockedScreen(billingState: _billingState);
    }

    // ✅ Normal flow for approved users
    if (_role != null) {
      return BottomNav(role: _role!);
    }

    // Load failed and we never got a role — send them back to sign in
    // rather than sitting on a blank screen.
    if (_loadFailed) return const LoginScreen();

    return const LoginScreen();
  }
}

// ==========================================
// 🛑 MOBILE APP WALL
// ==========================================
class MobileAppWall extends StatelessWidget {
  const MobileAppWall({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('images/logo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "KLOCKER is better in the app.",
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: 16),
              Text(
                "To ensure the best experience with time-tracking, offline "
                "sync, and instant notifications, mobile browser access is "
                "disabled. Please download the official Klocker app.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(height: 16),
              _storeButton(
                context,
                Icons.shop,
                "GET IT ON",
                "Google Play",
                () => launchUrl(Uri.parse('https://play.google.com')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _storeButton(
    BuildContext context,
    IconData icon,
    String topText,
    String bottomText,
    VoidCallback onTap,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: scheme.onSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: scheme.surface, size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Color.lerp(scheme.surface, scheme.onSurface, 0.3),
                  ),
                ),
                Text(
                  bottomText,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: scheme.surface),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
