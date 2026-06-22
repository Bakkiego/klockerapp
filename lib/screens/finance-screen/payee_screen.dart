import 'package:flutter/material.dart';
import '../../../supabase/repo/supabase_service.dart';
import 'components/add_payee_screen.dart';
import 'components/edit_payee_screen.dart';

class PayeeScreen extends StatefulWidget {
  const PayeeScreen({super.key});

  @override
  State<PayeeScreen> createState() => _PayeeScreenState();
}

class _PayeeScreenState extends State<PayeeScreen> {
  List<Map<String, dynamic>> _payees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPayees();
  }

  Future<void> _fetchPayees() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getPayees();
      if (mounted) {
        setState(() {
          _payees = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payees')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
              hintText: "Search Payees",
              trailing: [const Icon(Icons.search, color: Colors.grey)],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A36C)),
                  )
                : _payees.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _payees.length,
                    itemBuilder: (context, index) {
                      final payee = _payees[index];
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
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              0xFF00A36C,
                            ).withOpacity(0.1),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF00A36C),
                            ),
                          ),
                          title: Text(
                            payee['name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("${payee['bank_name']}"),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditPayeeScreen(initialPayerData: payee),
                                ),
                              );
                              if (result == true) _fetchPayees();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00A36C),
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPayeeScreen()),
          );
          if (result == true) _fetchPayees();
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Payee"),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            "No Payees Found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Text(
            "Add external accounts you frequently pay money to.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
