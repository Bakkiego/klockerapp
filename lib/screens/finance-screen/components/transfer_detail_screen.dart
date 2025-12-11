import 'package:flutter/material.dart';

import 'edit_transfer_screen.dart';

class TransferDetailScreen extends StatelessWidget {
  // Mock data representing a single selected transfer
  final Map<String, String> transferDetails;

  const TransferDetailScreen({
    super.key,
    // Require the details to be passed when navigating to this screen
    required this.transferDetails,
  });

  @override
  Widget build(BuildContext context) {
    final amount = transferDetails['amount'] ?? '0.00';
    final date = transferDetails['date'] ?? 'N/A';
    final fromAccount = transferDetails['from'] ?? 'N/A';
    final toAccount = transferDetails['to'] ?? 'N/A';
    final paymentMethod = transferDetails['paymentMethod'] ?? 'N/A';
    final ref = transferDetails['ref'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Details'),
        actions: [
          // Action button for editing the transfer (if allowed)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: Navigate to an Edit Transfer screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTransferScreen(
                    initialTransferData: {
                      "from": "Primary Savings (1234)",
                      "to": "Investment Portfolio (9012)",
                      "amount": "1,500.00",
                      "date": "Sep 15, 2025",
                      "paymentMethod": "Bank Transfer",
                      "ref": "TRN-98765-ABC",
                    },
                  ),
                ),
              );
              print('Edit transfer tapped');
            },
          ),
          // Action button for deleting the transfer (if allowed)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              // TODO: Show delete confirmation dialog
              print('Delete transfer tapped');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. Prominent Amount/Summary Block ---
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
                    '\$$amount',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
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

            // --- 2. Transfer Flow Section ---
            const Text(
              'Transfer Flow',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            // From Account Detail
            _buildDetailRow(
              context,
              icon: Icons.upload_file,
              label: 'FROM Account',
              value: fromAccount,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.arrow_downward, color: Colors.blueAccent),
            ),
            // To Account Detail
            _buildDetailRow(
              context,
              icon: Icons.download_outlined,
              label: 'TO Account',
              value: toAccount,
              isDestination: true,
            ),

            const SizedBox(height: 32),

            // --- 3. Additional Details Section ---
            const Text(
              'Transaction Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            _buildDetailRow(
              context,
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: date,
            ),
            _buildDetailRow(
              context,
              icon: Icons.credit_card,
              label: 'Payment Method',
              value: paymentMethod,
            ),
            _buildDetailRow(
              context,
              icon: Icons.numbers,
              label: 'Reference #',
              value: ref,
            ),
          ],
        ),
      ),
    );
  }

  // Reusable widget to display a single detail row
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isDestination = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isDestination ? Colors.green : Colors.red,
            size: 24,
          ),
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

// Example usage when navigating from the Transfer History screen:
/*
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TransferDetailScreen(
      transferDetails: {
        "from": "Primary Savings (1234)",
        "to": "Investment Portfolio (9012)",
        "amount": "1,500.00",
        "date": "Sep 15, 2025",
        "paymentMethod": "Bank Transfer",
        "ref": "TRN-98765-ABC",
      },
    ),
  ),
);
*/
