import 'package:flutter/material.dart'; // Import your enum
import 'package:klockerapp/utils/themes.dart';
import 'package:klockerapp/screens/login_screen.dart';
import 'package:klockerapp/components/bottom_nav.dart';
import 'package:klockerapp/supabase/supabase_config.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart'; // Import your service
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/app_enums.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUri,
    anonKey: SupabaseConfig.supabaseAnon,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check for existing session
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: KlockerappTheme.lightTheme,
      darkTheme: KlockerappTheme.darkTheme,
      // If a session exists, go to AuthGate to fetch the role.
      // Otherwise, go to Login.
      home: session != null
          ? AuthGate(userId: session.user.id)
          : const LoginScreen(),
    );
  }
}

// --- MOVE AUTHGATE OUTSIDE OF MYAPP ---
class AuthGate extends StatelessWidget {
  final String userId;
  const AuthGate({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Fetch the profile data from Supabase
      future: SupabaseService().getUserProfile(userId),
      builder: (context, snapshot) {
        // While loading the profile, show a spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            ),
          );
        }

        // If we have data, map the role and go to BottomNav
        if (snapshot.hasData && snapshot.data != null) {
          final String? roleStr = snapshot.data!['role'];
          final role = userRole.fromString(
            roleStr,
          ); // Using your new static method
          return BottomNav(role: role);
        }

        // Fallback to Login if profile fetch fails
        return const LoginScreen();
      },
    );
  }
}
