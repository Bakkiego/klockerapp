import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🚀 ADDED
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 ADDED
import '../../../supabase/repo/supabase_service.dart';
import 'components/add_deposit_screen.dart'; // Ensure path is correct

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  List<Map<String, dynamic>> _deposits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDeposits();
  }

  Future<void> _fetchDeposits() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getDeposits();
      if (mounted) {
        setState(() {
          _deposits = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 Grabs the live currency symbol from settings!
    final currency = context.watch<UserProvider>().currencySymbol;

    return Scaffold(
      appBar: AppBar(title: const Text('Deposits')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
              hintText: "Search Deposits",
              trailing: [const Icon(Icons.search, color: Colors.grey)],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                : _deposits.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _deposits.length,
                    itemBuilder: (context, index) {
                      final deposit = _deposits[index];

                      // Safely parse nested account name and amount
                      final accountName =
                          deposit['accounts']?['name'] ?? 'Unknown Account';
                      final amountStr = deposit['amount']?.toString() ?? '0.00';
                      final notes = deposit['notes']?.toString() ?? 'Deposit';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 6.0,
                        ),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.withOpacity(0.1),
                            child: const Icon(
                              Icons.arrow_downward,
                              color: Colors.green,
                            ),
                          ),
                          title: Text(
                            accountName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            notes,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15),
                          ),
                          trailing: Text(
                            // 🚀 CHANGED: Using dynamic currency
                            "+$currency$amountStr",
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewDepositScreen()),
          );
          if (result == true) _fetchDeposits();
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        label: const Text(
          "Deposit",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            "No Deposits Yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Record money coming into your accounts.",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
