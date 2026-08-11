import 'package:flutter/material.dart';
import 'package:klockerapp/models/app_enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/bottom_nav.dart';
import '../supabase/repo/supabase_service.dart';
import 'package:provider/provider.dart';
import 'package:klockerapp/providers/user_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:klockerapp/screens/pending_approval_screen.dart';

class LoginScreen extends StatefulWidget {
  static String id = 'login_screen';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCont = TextEditingController();
  final passCont = TextEditingController();
  bool _isLoading = false;

  void _showFriendlyError(String rawError, {bool isAuthError = false}) {
    String friendlyMessage = "Something went wrong. Please try again.";

    if (isAuthError) {
      if (rawError.toLowerCase().contains("invalid login credentials")) {
        friendlyMessage = "Incorrect email or password. Let's try that again.";
      } else if (rawError.toLowerCase().contains("email not confirmed")) {
        friendlyMessage =
            "Please check your email and click the verification link before logging in.";
      } else if (rawError.toLowerCase().contains("user not found")) {
        friendlyMessage = "We couldn't find an account with that email.";
      } else {
        friendlyMessage = rawError;
      }
    } else {
      if (rawError.contains("SocketException") ||
          rawError.contains("Failed host lookup")) {
        friendlyMessage =
            "No internet connection. Please check your Wi-Fi or cellular data.";
      } else if (rawError.contains("single JSON object")) {
        friendlyMessage =
            "Your account is set up, but your profile data is incomplete. Please contact support.";
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(friendlyMessage)),
            ],
          ),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _handleSignIn() async {
    if (emailCont.text.isEmpty || passCont.text.isEmpty) {
      _showFriendlyError(
        "Please enter both your email and password.",
        isAuthError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = await SupabaseService().signInUser(
        emailCont.text.trim(),
        passCont.text.trim(),
      );

      final userRole role = userRole.fromString(userData['role'] ?? 'employee');
      final String approvalStatus =
          userData['approval_status'] ?? 'approved'; // 🚀 Grab status

      if (mounted) {
        // 🚀 GATE 1: Are they pending? Send to Waiting Room.
        if (approvalStatus == 'pending') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PendingApprovalScreen(),
            ),
          );
          return;
        } else if (approvalStatus == 'rejected') {
          await Supabase.instance.client.auth.signOut();
          _showFriendlyError(
            "Access Denied: Your account has been rejected by HR.",
          );
          return;
        }
        // ✅ If we get here, they are approved! Let them into the system.
        context.read<UserProvider>().setUserProfile(userData);
        context.read<UserProvider>().setChatReady(
          userData['chat_ready'] ?? true,
        ); // 🚀 new
        // 🚀 THE NEW INJECTION: Fetch and set permissions on manual login
        final String legacyRole = userData['role'] ?? 'employee';
        final String? customRoleId = userData['custom_role_id'];

        final permissions = await SupabaseService().getUserPermissions(
          customRoleId,
          legacyRole,
        );
        context.read<UserProvider>().setPermissions(
          permissions,
          hasCustomRole: customRoleId != null,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomNav(role: role)),
        );
      }
    } on AuthException catch (e) {
      _showFriendlyError(e.message, isAuthError: true);
    }
  }

  Future<void> _launchWebsite() async {
    final Uri url = Uri.parse(
      'https://yourwebsite.com',
    ); // TODO: Replace with your actual URL
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showFriendlyError(
        "Could not open the browser. Please visit our website manually.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      body: SafeArea(
        // 🚀 WEB FIX: Center and Constrain the width!
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 450,
            ), // Locks the width for web
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: SizedBox(
                      width: 120,
                      child: Image.asset('images/logo.png'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Welcome Back",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign in to manage your workforce",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // --- THE FORM AREA ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? theme.colorScheme.surface : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black54
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: emailCont,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: passCont,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _isLoading
                            ? const CircularProgressIndicator(
                                color: Color(0xFF00A36C),
                              )
                            : ElevatedButton(
                                onPressed: _handleSignIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00A36C),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  "Sign In",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- OPTION A: THE "READER APP" FOOTER ---
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  TextButton(
                    onPressed: _launchWebsite,
                    child: const Text(
                      "Set up your workspace at klockerapp.com",
                      style: TextStyle(
                        color: Color(0xFF00A36C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
