import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // 🚀 ADDED
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 ADDED
import '../../../supabase/repo/supabase_service.dart';

class AddTransferScreen extends StatefulWidget {
  const AddTransferScreen({super.key});

  @override
  State<AddTransferScreen> createState() => _AddTransferScreenState();
}

class _AddTransferScreenState extends State<AddTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _refController = TextEditingController();

  String? _fromAccountId;
  String? _toAccountId;
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  Future<void> _fetchAccounts() async {
    try {
      final accounts = await SupabaseService().getAccounts();
      if (mounted)
        setState(() {
          _accounts = accounts;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitTransfer() async {
    // Redundant safeguard just in case
    if (_fromAccountId == _toAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Source and destination accounts must be different.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final amount = double.parse(_amountController.text.replaceAll(',', ''));
        final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

        await SupabaseService().addFinancialTransfer(
          fromAccountId: _fromAccountId!,
          toAccountId: _toAccountId!,
          amount: amount,
          date: formattedDate,
          ref: _refController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transfer Complete!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 Grabs the live currency symbol from settings!
    final currency = context.watch<UserProvider>().currencySymbol;

    return Scaffold(
      appBar: AppBar(title: const Text('New Transfer')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          // 🚀 RULE 1: STRICT LOCKOUT IF < 2 ACCOUNTS EXIST 🚀
          : _accounts.length < 2
          ? _buildNotEnoughAccountsState()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // FROM Account (Blue Theme)
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'From Account',
                      prefixIcon: Icon(
                        Icons.upload_rounded,
                        color: Colors.blue.shade400,
                      ),
                    ),
                    value: _fromAccountId,
                    items: _accounts
                        .map(
                          (acc) => DropdownMenuItem<String>(
                            value: acc['id'],
                            child: Text(acc['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _fromAccountId = val;
                        // 🚀 RULE 2: AUTO-RESET IF THEY TRY TO MATCH THEM 🚀
                        if (_toAccountId == _fromAccountId) {
                          _toAccountId = null;
                        }
                      });
                    },
                    validator: (val) => val == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // TO Account (Green Theme)
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'To Account',
                      prefixIcon: Icon(
                        Icons.download_rounded,
                        color: Colors.green.shade400,
                      ),
                    ),
                    value: _toAccountId,
                    items: _accounts
                        .map(
                          (acc) => DropdownMenuItem<String>(
                            value: acc['id'],
                            child: Text(acc['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _toAccountId = val),
                    validator: (val) {
                      if (val == null) return 'Required';
                      // 🚀 RULE 3: VALIDATOR REJECTION 🚀
                      if (val == _fromAccountId)
                        return 'Cannot transfer to the same account';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText:
                          '$currency ', // 🚀 CHANGED: Using dynamic currency
                      prefixIcon: const Icon(Icons.swap_horiz),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Date
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ref
                  TextFormField(
                    controller: _refController,
                    decoration: const InputDecoration(
                      labelText: 'Reference # (Optional)',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                  const SizedBox(height: 48),

                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitTransfer,
                    icon: const Icon(Icons.sync_alt),
                    label: Text(
                      _isSubmitting ? 'Transferring...' : 'Execute Transfer',
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Beautiful empty state for when they don't have enough accounts
  Widget _buildNotEnoughAccountsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 24),
            const Text(
              "More Accounts Needed",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "You currently have less than two bank accounts registered. To perform a transfer, you must have at least one source account and one destination account.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
