import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // 🚀 ADDED
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 ADDED
import '../../../supabase/repo/supabase_service.dart';
import 'components/transfer_detail_screen.dart';
import 'components/add_transfer_screen.dart'; // Ensure this points to the add screen we built!

class ManageTransferScreen extends StatefulWidget {
  const ManageTransferScreen({super.key});

  @override
  State<ManageTransferScreen> createState() => _ManageTransferScreenState();
}

class _ManageTransferScreenState extends State<ManageTransferScreen> {
  List<Map<String, dynamic>> _transfers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransfers();
  }

  Future<void> _fetchTransfers() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getFinancialTransfers();
      if (mounted) {
        setState(() {
          _transfers = data;
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
      appBar: AppBar(title: const Text('Transfer History')),
      body: Column(
        children: [
          // 1. Search Bar Area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
              hintText: "Search Transfers...",
              side: MaterialStateProperty.all(
                const BorderSide(color: Colors.green),
              ),
              // leading: [const Icon(Icons.search, color: Colors.grey)],
              trailing: [const Icon(Icons.search, color: Colors.grey)],
            ),
          ),

          // 2. The Scrollable List of Transfer Cards
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  )
                : _transfers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _transfers.length,
                    itemBuilder: (context, index) {
                      final transfer = _transfers[index];

                      // Extract safe dynamic data
                      final fromAccount =
                          transfer['from_account']?['name'] ?? 'Unknown';
                      final toAccount =
                          transfer['to_account']?['name'] ?? 'Unknown';
                      final amountStr =
                          transfer['amount']?.toString() ?? '0.00';

                      String dateStr =
                          transfer['transfer_date']?.toString() ?? '';
                      try {
                        if (dateStr.isNotEmpty) {
                          dateStr = DateFormat(
                            'MMM dd, yyyy',
                          ).format(DateTime.parse(dateStr));
                        }
                      } catch (_) {}

                      return GestureDetector(
                        onTap: () async {
                          // Navigate to Detail and wait for a possible delete/update
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransferDetailScreen(
                                transferDetails: transfer,
                              ),
                            ),
                          );
                          if (result == true) _fetchTransfers();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 6.0,
                          ),
                          child: Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Side: Transfer Flow (Blue FROM -> Green TO)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fromAccount,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4.0,
                                          ),
                                          child: Icon(
                                            Icons.arrow_downward,
                                            size: 16,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                        Text(
                                          toAccount,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Right Side: Amount
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        height: 12,
                                      ), // Align a bit lower to match the flow visually
                                      Text(
                                        // 🚀 CHANGED: Using dynamic currency
                                        "$currency$amountStr",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                          color: Colors
                                              .black87, // Kept neutral so it doesn't clash with Blue/Green
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Icon(
                                        Icons.sync_alt,
                                        color: Colors.grey.shade300,
                                        size: 20,
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

      // 3. Floating Action Button (FAB)
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () async {
          // 🚀 Navigate to the actual Add Screen, wait for result to refresh
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransferScreen()),
          );
          if (result == true) _fetchTransfers();
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.swap_horiz),
        label: const Text(
          "Transfer",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sync_alt, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "No Transfers Found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Text(
            "Move money between your internal accounts.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
