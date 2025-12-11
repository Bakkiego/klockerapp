import 'package:flutter/material.dart';

// Assuming you have EditAccountScreen imported here
import 'edit_account_screen.dart';

class AccountDetailScreen extends StatelessWidget {
  // Receives the data map from the Accounts List Screen
  final Map<String, String> accountDetails;

  const AccountDetailScreen({super.key, required this.accountDetails});

  // Helper to determine balance color
  Color _getBalanceColor(String balanceText) {
    final cleanedBalance = balanceText
        .replaceAll(',', '')
        .replaceAll('\$', '')
        .replaceAll('-', '');
    final balance = double.tryParse(cleanedBalance) ?? 0.0;

    // Check if the balance is explicitly negative in the string
    if (balanceText.contains('-')) return Colors.red.shade700;
    if (balance > 0) return Colors.green.shade700;
    return Colors.black87;
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Pass the account details to the Edit screen
        builder: (context) =>
            EditAccountScreen(initialAccountData: accountDetails),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Account Deletion'),
        content: Text(
          'Are you sure you want to delete the account: ${accountDetails['name']}? This action is permanent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement actual account deletion logic
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to the list screen
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Account Deleted!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanceColor = _getBalanceColor(accountDetails['balance'] ?? '0.00');

    return Scaffold(
      appBar: AppBar(
        title: Text(accountDetails['name'] ?? 'Account Details'),
        actions: [
          // Edit Button in AppBar
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _navigateToEdit(context),
          ),
          // Delete Button in AppBar
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. Prominent Balance Block ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: balanceColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: balanceColor.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Text(
                    accountDetails['type'] ?? 'Account Type',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Current Balance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${accountDetails['balance'] ?? '0.00'}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: balanceColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- 2. Details Section ---
            const Text(
              'Account Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            _buildDetailRow('Account Name', accountDetails['name'] ?? 'N/A'),
            _buildDetailRow('Account Type', accountDetails['type'] ?? 'N/A'),
            _buildDetailRow(
              'Account Number',
              accountDetails['number'] ?? 'N/A',
            ),
            _buildDetailRow('Branch Name', accountDetails['branch'] ?? 'N/A'),
            _buildDetailRow('Code', accountDetails['code'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  // Reusable widget to display a single detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
