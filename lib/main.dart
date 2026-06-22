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
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:klockerapp/screens/pending_approval_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
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

      // 🚀 1. THE NEW GLOBAL GATEKEEPER
      builder: (context, child) {
        // If we are on the web, check the screen size
        if (kIsWeb) {
          return LayoutBuilder(
            builder: (context, constraints) {
              // If the screen is mobile-sized, block everything!
              if (constraints.maxWidth < 600) {
                return const MobileWebBlockerScreen();
              }
              // If it's a big screen, show the app normally
              return child!;
            },
          );
        }
        // If they downloaded the actual App Store/Play Store app, let them in.
        return child!;
      },

      home: session != null
          ? AuthGate(userId: session.user.id)
          : const LoginScreen(),
    );
  }
}

// 🚀 This function measures the screen before drawing the app
Widget _buildWebResponsiveGate(Widget mainContent) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // If screen is smaller than 600 pixels wide (standard phone size)
      if (constraints.maxWidth < 600) {
        return const MobileWebBlockerScreen();
      }
      // If it's a tablet or laptop, let them in!
      return mainContent;
    },
  );
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
  String? _approvalStatus; // 🚀 NEW: Track approval status

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

        // 🚀 THE NEW INJECTION: Fetch and set permissions silently on app start
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

    // 🚀 NEW: The Security Locks
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

class MobileWebBlockerScreen extends StatelessWidget {
  const MobileWebBlockerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon or Logo
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A36C).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_android,
                    size: 64,
                    color: Color(0xFF00A36C),
                  ),
                ),
                const SizedBox(height: 32),

                // Text
                const Text(
                  "Get the Mobile App",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  "The web dashboard is optimized for tablets and desktop computers. For the best experience on your phone, please download the official KlockerApp.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                // Download Buttons (You can link these to your actual store URLs later)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Add App Store Link via url_launcher
                    },
                    icon: const Icon(Icons.apple),
                    label: const Text("Download for iOS"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Add Google Play Link via url_launcher
                    },
                    icon: const Icon(Icons.shop), // Generic play store icon
                    label: const Text("Download for Android"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF00A36C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
