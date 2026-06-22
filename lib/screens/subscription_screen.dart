import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionGateScreen extends StatefulWidget {
  final String tenantId;
  const SubscriptionGateScreen({super.key, required this.tenantId});

  @override
  State<SubscriptionGateScreen> createState() => _SubscriptionGateScreenState();
}

class _SubscriptionGateScreenState extends State<SubscriptionGateScreen> {
  bool _isLoading = false;

  Future<void> _startPayFastCheckout() async {
    setState(() => _isLoading = true);

    try {
      // 1. Ask Supabase Edge Function to generate the secure PayFast link
      final response = await Supabase.instance.client.functions.invoke(
        'generate-payfast-link',
        body: {'tenant_id': widget.tenantId},
      );

      final checkoutUrl =
          response.data['url']; // The secure link from your backend

      // 2. Open the browser to PayFast
      final url = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch PayFast checkout.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error launching checkout: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Color(0xFF00A36C),
              ),
              const SizedBox(height: 24),
              const Text(
                "Start Your 14-Day Free Trial",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "You are one step away from unlocking KlockerApp for your entire company. Enter your payment details securely via PayFast to begin. You won't be charged a single cent until day 15.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.credit_card),
                  label: Text(
                    _isLoading
                        ? "Connecting..."
                        : "Continue to Secure Checkout",
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A36C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    setState(() => _isLoading = true);

                    try {
                      // 1. Invoke the remote Supabase Edge Function safely
                      final response = await Supabase.instance.client.functions
                          .invoke(
                            'payfast-checkout',
                            body: {'tenant_id': widget.tenantId},
                          );

                      final checkoutUrl = response.data['url'];

                      // 2. Open the URL in the phone's secure native browser
                      final url = Uri.parse(checkoutUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        throw 'Could not launch PayFast checkout.';
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
