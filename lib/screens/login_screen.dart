import 'package:flutter/material.dart';
import 'package:klockerapp/models/app_enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/bottom_nav.dart';
import '../supabase/repo/supabase_service.dart';
import 'package:provider/provider.dart';
import 'package:klockerapp/providers/user_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:klockerapp/screens/pending_approval_screen.dart';
import 'package:klockerapp/screens/subscription_locked_screen.dart';

import 'help-screens/change_password_screen.dart';

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

  @override
  void dispose() {
    emailCont.dispose();
    passCont.dispose();
    super.dispose();
  }

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
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: scheme.onError),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  friendlyMessage,
                  style: TextStyle(color: scheme.onError),
                ),
              ),
            ],
          ),
          backgroundColor: scheme.error,
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

      if (!mounted) return;

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

      // 🔒 GATE 2: Is the company's subscription still live?
      //
      // This has to happen BEFORE permissions load. Every tenant table
      // carries a restrictive `subscription_active` policy, so a lapsed
      // tenant that gets past here reaches a dashboard where every query
      // returns zero rows — which reads as a broken app, not as an unpaid
      // invoice. Nothing is deleted either way; the gate is read-only.
      final bool tenantActive = await SupabaseService().isTenantActive();
      if (!mounted) return;

      if (!tenantActive) {
        // Only fetched on the unhappy path — the lock screen needs the
        // status, expiry date and tier to tell them what to renew.
        final billingState = await SupabaseService().getBillingState();
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SubscriptionLockedScreen(billingState: billingState),
          ),
        );
        return;
      }

      // ✅ If we get here, they are approved and paid up. Let them in.
      context.read<UserProvider>().setUserProfile(userData);
      context.read<UserProvider>().setChatReady(userData['chat_ready'] ?? true);
      final tenantCurrency = userData['currency'];
      if (tenantCurrency != null) {
        context.read<UserProvider>().setCurrencyFromCode(tenantCurrency);
      }
      final String legacyRole = userData['role'] ?? 'employee';
      final String? customRoleId = userData['custom_role_id'];

      final permissions = await SupabaseService().getUserPermissions(
        customRoleId,
        legacyRole,
      );
      if (!mounted) return;
      context.read<UserProvider>().setPermissions(
        permissions,
        hasCustomRole: customRoleId != null,
      );

      final planState = await SupabaseService().getPlanState();
      if (!mounted) return;
      context.read<UserProvider>().setPlan(planState);

      if (userData['must_change_password'] == true) {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const ChangePasswordScreen(isForced: true),
          ),
        );

        // PopScope blocks the back gesture, so this only happens if
        // something unusual dismissed the screen. Fail closed.
        if (changed != true) {
          await Supabase.instance.client.auth.signOut();
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        if (!mounted) return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNav(role: role)),
      );
    } on AuthException catch (e) {
      _showFriendlyError(e.message, isAuthError: true);
    } catch (e) {
      _showFriendlyError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchWebsite() async {
    final Uri url = Uri.parse('https://klockerapp.com');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showFriendlyError(
        "Could not open the browser. Please visit klockerapp.com manually.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // --- THE FORM AREA ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.shadow.withOpacity(0.08),
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
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: passCont,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!_isLoading) _handleSignIn();
                          },
                          decoration: const InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _handleSignIn,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  "Sign In",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: _launchWebsite,
                    child: Text(
                      "Set up your workspace at klockerapp.com",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.primary,
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
