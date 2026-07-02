import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🚀 ADDED
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 ADDED
import '../../../supabase/repo/supabase_service.dart';

import 'components/add_new_account_screen.dart';
import 'components/account_detail_screen.dart';

class AccountsListScreen extends StatefulWidget {
  const AccountsListScreen({super.key});

  @override
  State<AccountsListScreen> createState() => _AccountsListScreenState();
}

class _AccountsListScreenState extends State<AccountsListScreen> {
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  Future<void> _fetchAccounts() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getAccounts();
      if (mounted) {
        setState(() {
          _accounts = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching accounts: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🚀 Updated to accept Map<String, dynamic>
  void _navigateToDetailScreen(Map<String, dynamic> accountData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountDetailScreen(accountDetails: accountData),
      ),
    );
  }

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

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts List')),
      body: Column(
        children: [
          // Search Bar Section
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SearchBar(
                    elevation: WidgetStateProperty.all(0),
                    backgroundColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ),
                    hintText: "Search Accounts",
                    trailing: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.search, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Accounts List Section (With Loading and Empty States)
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A36C)),
                  )
                : _accounts.isEmpty
                ? _buildEmptyState() // 🚀 The new Empty State Widget!
                : ListView.builder(
                    itemCount: _accounts.length,
                    itemBuilder: (context, index) {
                      final account = _accounts[index];

                      // Safely parse database values
                      final balanceStr =
                          account['balance']?.toString() ?? '0.00';

                      // 🚀 Pass the currency here to ensure the color math works perfectly
                      final balanceColor = _getBalanceColor(
                        balanceStr,
                        currency,
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 6.0,
                        ),
                        child: Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _navigateToDetailScreen(account),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Icon based on account type
                                  CircleAvatar(
                                    backgroundColor: const Color(
                                      0xFF00A36C,
                                    ).withOpacity(0.1),
                                    child: const Icon(
                                      Icons.account_balance_wallet,
                                      color: Color(0xFF00A36C),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Account Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          account['name'] ?? 'Unnamed Account',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${account['account_type'] ?? 'Standard'}",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Balance
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        "Balance",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        // 🚀 Inject the dynamic currency
                                        "$currency$balanceStr",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          color: balanceColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        backgroundColor: const Color(0xFF00A36C),
        foregroundColor: Colors.white,
        onPressed: () async {
          // 🚀 Wait for the Add Screen to pop back
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddNewAccountScreen(),
            ),
          );

          // 🚀 If an account was added (result is true), refresh the list!
          if (result == true) {
            _fetchAccounts();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- NEW: Custom Empty State Widget ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF00A36C).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance,
              size: 64,
              color: const Color(0xFF00A36C).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No Accounts Found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Add your first bank or cash account\nto start tracking your finances.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
