import 'package:flutter/material.dart';
import '../../../supabase/repo/supabase_service.dart';
import 'components/add_payers_screen.dart'; // Ensure path is correct
import 'components/edit_payer_screen.dart'; // Ensure path is correct

class PayersScreen extends StatefulWidget {
  const PayersScreen({super.key});

  @override
  State<PayersScreen> createState() => _PayersScreenState();
}

class _PayersScreenState extends State<PayersScreen> {
  List<Map<String, dynamic>> _payers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPayers();
  }

  Future<void> _fetchPayers() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getPayers();
      if (mounted) {
        setState(() {
          _payers = data;
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
      appBar: AppBar(title: const Text('Payers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
              hintText: "Search Payers",
              trailing: [const Icon(Icons.search, color: Colors.grey)],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                : _payers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _payers.length,
                    itemBuilder: (context, index) {
                      final payer = _payers[index];
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
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: const Icon(
                              Icons.business,
                              color: Colors.green,
                            ),
                          ),
                          title: Text(
                            payer['name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${payer['bank_name'] ?? 'External Source'}",
                          ),
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
                                      EditPayerScreen(initialPayerData: payer),
                                ),
                              );
                              if (result == true) _fetchPayers();
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
        heroTag: null,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPayerScreen()),
          );
          if (result == true) _fetchPayers();
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Payer"),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            "No Payers Found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Text(
            "Add clients or entities that send you money.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
