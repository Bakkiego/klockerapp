import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // 🚀 ADDED
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 ADDED
import 'edit_transfer_screen.dart';

class TransferDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transferDetails;

  const TransferDetailScreen({super.key, required this.transferDetails});

  @override
  Widget build(BuildContext context) {
    // 🚀 Grabs the live currency symbol from settings!
    final currency = context.watch<UserProvider>().currencySymbol;

    final amount = transferDetails['amount']?.toString() ?? '0.00';
    final fromAccount =
        transferDetails['from_account']?['name'] ?? 'Unknown Account';
    final toAccount =
        transferDetails['to_account']?['name'] ?? 'Unknown Account';
    final ref = transferDetails['ref']?.toString() ?? '-';

    String date = transferDetails['transfer_date']?.toString() ?? 'N/A';
    try {
      if (date != 'N/A') {
        date = DateFormat('MMM dd, yyyy').format(DateTime.parse(date));
      }
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditTransferScreen(initialTransferData: transferDetails),
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
            // Amount Block
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Transfer Amount',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    // 🚀 CHANGED: Using dynamic currency
                    '$currency$amount',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completed on $date',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Flow Block (Blue -> Green)
            const Text(
              'Transfer Flow',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDetailRow(
              icon: Icons.upload_file,
              label: 'FROM',
              value: fromAccount,
              color: Colors.blue.shade700,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Icon(Icons.arrow_downward, color: Colors.grey.shade400),
            ),
            _buildDetailRow(
              icon: Icons.download_outlined,
              label: 'TO',
              value: toAccount,
              color: Colors.green.shade700,
            ),

            const SizedBox(height: 32),

            // Details Block
            const Text(
              'Transaction Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: date,
              color: Colors.grey.shade600,
            ),
            _buildDetailRow(
              icon: Icons.numbers,
              label: 'Reference #',
              value: ref,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
