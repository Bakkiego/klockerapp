import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:klockerapp/screens/login_screen.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:klockerapp/utils/custom_theme/k_palette.dart';

/// Shown instead of the app when a tenant's subscription has lapsed.
///
/// Nothing is deleted and nothing is irreversible — the moment the payment
/// lands and the ITN pushes `subscription_expires_at` forward, "I've paid"
/// re-checks and lets them straight back in.
class SubscriptionLockedScreen extends StatefulWidget {
  /// The map returned by `my_billing_state()`. Null is tolerated — the
  /// screen still renders, just without the company name and dates.
  final Map<String, dynamic>? billingState;

  const SubscriptionLockedScreen({super.key, this.billingState});

  @override
  State<SubscriptionLockedScreen> createState() =>
      _SubscriptionLockedScreenState();
}

class _SubscriptionLockedScreenState extends State<SubscriptionLockedScreen> {
  bool _isChecking = false;
  Map<String, dynamic>? _state;

  // TODO: point this at your real billing page.
  static const _billingUrl = 'https://klockerapp.com/billing';

  @override
  void initState() {
    super.initState();
    _state = widget.billingState;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: isError
              ? theme.textTheme.bodyMedium?.copyWith(color: scheme.onError)
              : null,
        ),
        backgroundColor: isError ? scheme.error : null,
      ),
    );
  }

  /// Re-reads the billing state. If the payment has landed, drop this
  /// screen and let the app re-resolve the route.
  Future<void> _recheck() async {
    setState(() => _isChecking = true);
    try {
      final fresh = await SupabaseService().getBillingState();
      if (!mounted) return;

      if (fresh?['is_active'] == true) {
        // Simplest reliable way back in: bounce through the login screen,
        // which rebuilds from the restored session.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }

      setState(() {
        _state = fresh;
        _isChecking = false;
      });
      _showSnack("We can't see a payment yet. Try again in a few minutes.");
    } catch (e) {
      if (!mounted) return;
      setState(() => _isChecking = false);
      _showSnack("Couldn't check your subscription: $e", isError: true);
    }
  }

  Future<void> _openBilling() async {
    final uri = Uri.parse(_billingUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnack(
        "Couldn't open the browser. Visit $_billingUrl",
        isError: true,
      );
    }
  }

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String? get _companyName => _state?['company_name']?.toString();

  /// "Your access ended on 3 October 2026", when we know the date.
  String? get _endedOn {
    final raw = _state?['expires_at'];
    if (raw == null) return null;
    final date = DateTime.tryParse(raw.toString())?.toLocal();
    if (date == null) return null;
    return DateFormat('d MMMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = context.status;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: status.pendingBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_clock_outlined,
                      size: 48,
                      color: status.pendingFg,
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    "Subscription not renewed",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    _companyName == null
                        ? "Your workspace is paused until the subscription "
                              "is renewed."
                        : "$_companyName is paused until the subscription "
                              "is renewed.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),

                  if (_endedOn != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Last paid period ended $_endedOn.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // The reassurance is the point — people assume "locked"
                  // means "wiped".
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: scheme.outline),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 20,
                          color: context.brandText,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Nothing has been deleted. Your staff records, "
                            "attendance history and payslips are all still "
                            "here and come straight back when you renew — "
                            "however long it takes.",
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _openBilling,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text("Renew subscription"),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _isChecking ? null : _recheck,
                      child: _isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("I've paid — check again"),
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: _isChecking ? null : _signOut,
                    child: const Text("Sign out"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
