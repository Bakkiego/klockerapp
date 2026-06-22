import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🚀 ADDED
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 ADDED
import 'edit_account_screen.dart';

class AccountDetailScreen extends StatelessWidget {
  // 🚀 Accepts the dynamic map from Supabase
  final Map<String, dynamic> accountDetails;

  const AccountDetailScreen({super.key, required this.accountDetails});

  // 🚀 Updated to accept the dynamic currency string for safe math parsing
  Color _getBalanceColor(String balanceText, String currencySymbol) {
    final cleanedBalance = balanceText
        .replaceAll(',', '')
        .replaceAll(currencySymbol, '');
    final balance = double.tryParse(cleanedBalance) ?? 0.0;

    if (balance > 0) return Colors.green.shade700;
    if (balance < 0) return Colors.red.shade700;
    return Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 Grabs the live currency symbol from settings!
    final currency = context.watch<UserProvider>().currencySymbol;

    // 🚀 THE FIX: Safely extract and convert all dynamic database values to Strings!
    final String name = accountDetails['name']?.toString() ?? 'Unnamed Account';
    final String balanceStr = accountDetails['balance']?.toString() ?? '0.00';
    final String type =
        accountDetails['account_type']?.toString() ?? 'Standard';
    final String branch = accountDetails['branch']?.toString() ?? 'Main';
    final String code = accountDetails['code']?.toString() ?? 'N/A';

    // 🚀 Pass the currency here to ensure the color math works perfectly
    final balanceColor = _getBalanceColor(balanceStr, currency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditAccountScreen(initialAccountData: accountDetails),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Top Balance Card ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF00A36C).withOpacity(0.1),
                      child: const Icon(
                        Icons.account_balance,
                        size: 32,
                        color: Color(0xFF00A36C),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(type),
                      backgroundColor: Colors.green,
                      side: BorderSide.none,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "CURRENT BALANCE",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      // 🚀 Inject the dynamic currency
                      "$currency$balanceStr",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: balanceColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Detailed Information List ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Text(
                "Account Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.business, "Branch", branch),
                  const Divider(height: 1),
                  _buildInfoRow(Icons.qr_code, "Code", code),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build consistent info rows
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 20),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
