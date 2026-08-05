import 'package:flutter/material.dart';
import 'package:klockerapp/utils/themes.dart';
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
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 🚀 Required for detecting platform and launching URLs
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "config.env");
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'KlockerApp',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: KlockerappTheme.lightTheme,
      darkTheme: KlockerappTheme.darkTheme,

      // 🚀 THE UPGRADED OS-BASED GATEKEEPER
      builder: (context, child) {
        // If they are on the Web AND using a Mobile OS (iOS/Android)...
        if (kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.android)) {
          return const MobileAppWall(); // 🛑 Throw up the mobile wall!
        }
        // Otherwise, let them proceed normally
        return child!;
      },

      home: session != null
          ? AuthGate(userId: session.user.id)
          : const LoginScreen(),
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
      if (mounted) {
        context.read<UserProvider>().setUserProfile(data);

        // Fetch and set permissions silently on app start
        final String legacyRole = data['role'] ?? 'employee';
        final String? customRoleId = data['custom_role_id'];

        final permissions = await SupabaseService().getUserPermissions(
          customRoleId,
          legacyRole,
        );
        context.read<UserProvider>().setPermissions(permissions);

        setState(() {
          _role = userRole.fromString(legacyRole);
          _approvalStatus = data['approval_status'] ?? 'approved';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("AuthGate Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00A36C)),
        ),
      );
    }

    // The Security Locks
    if (_approvalStatus == 'pending') {
      return const PendingApprovalScreen();
    }

    if (_approvalStatus == 'rejected') {
      // Safely force a sign-out in the background and boot them to Login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Supabase.instance.client.auth.signOut();
      });
      return const LoginScreen();
    }

    // ✅ Normal flow for approved users
    if (_role != null) {
      return BottomNav(role: _role!);
    }

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
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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
                  color: const Color(0xFF4BAE4F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    "K",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "KLOCKER is better in the app.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "To ensure the best experience with time-tracking, offline sync, and instant notifications, mobile browser access is disabled. Please download the official Klocker app.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // 🚀 Replace these URLs with your actual App Store / Play Store links
              _storeButton(
                Icons.apple,
                "Download on the",
                "App Store",
                () => launchUrl(Uri.parse('https://apps.apple.com')),
              ),
              const SizedBox(height: 16),
              _storeButton(
                Icons.shop, // Or FontAwesomeIcons.googlePlay
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
    IconData icon,
    String topText,
    String bottomText,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  bottomText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
