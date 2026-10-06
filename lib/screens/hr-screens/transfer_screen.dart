import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import '../employee-screens/components/employee_screen_components/employee_tile.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _searchResults = [];
  List<String> _allBranchNames = [];
  List<String> _branchSuggestions = [];
  Map<String, dynamic>? _selectedEmployee;
  bool _isSearching = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _loadBranches();
  }

  @override
  void dispose() {
    // Neither controller was being disposed.
    _dateController.dispose();
    _branchNameController.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    final names = await SupabaseService().getBranchNames();
    if (mounted) {
      setState(() {
        _allBranchNames = names;
      });
    }
  }

  void _onBranchSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _branchSuggestions = []);
      return;
    }

    setState(() {
      _branchSuggestions = _allBranchNames
          .where((name) => name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _onSearchChanged(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final dynamic results = await SupabaseService().searchEmployees(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results == null
            ? []
            : List<Map<String, dynamic>>.from(results);
      });
    } catch (e) {
      debugPrint("Search error: $e");
      if (mounted) setState(() => _searchResults = []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _selectDate() async {
    // The builder override is gone — datePickerTheme handles both modes.
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  Future<void> _processTransfer() async {
    final scheme = Theme.of(context).colorScheme;

    if (_selectedEmployee == null ||
        _branchNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an employee and enter a target branch."),
        ),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      await SupabaseService().transferEmployee(
        employeeId: _selectedEmployee!['id'],
        newBranchName: _branchNameController.text.trim(),
        oldBranchName: _selectedEmployee!['branch'],
        transferDate: _selectedDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transfer processed")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Transfer failed: $e"),
            backgroundColor: scheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Process Transfer'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 24.0,
              left: 20.0,
              right: 20.0,
              bottom: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // 1. EMPLOYEE SELECTION
                // ==========================================
                Text("Select Employee", style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),

                if (_selectedEmployee == null) ...[
                  SearchBar(
                    hintText: "Search employee to transfer...",
                    onChanged: _onSearchChanged,
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    leading: Icon(
                      Icons.search,
                      color: scheme.onSurfaceVariant,
                    ),
                    trailing: [
                      if (_isSearching)
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: _searchResults.isEmpty
                        ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? "Search for an employee to begin"
                            : "No employees found",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                        : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final emp = _searchResults[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: scheme.outline),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4.0,
                            ),
                            child: EmployeeTile(
                                  () => setState(() {
                                _selectedEmployee = emp;
                                _searchResults = [];
                                _searchQuery = "";
                              }),
                              emp['full_name'] ?? "Unknown",
                              Icon(
                                Icons.add_circle_outline,
                                color: scheme.primary,
                              ),
                              emp['branch'] ?? "Main Branch",
                              emp['role'] ?? "Staff",
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  // Selected employee — the tinted container is the
                  // primaryContainer pair, so one value instead of an
                  // isDark ternary over two opacities.
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: scheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: EmployeeTile(
                            () {},
                        _selectedEmployee!['full_name'],
                        IconButton(
                          icon: Icon(
                            Icons.cancel,
                            color: scheme.onPrimaryContainer,
                          ),
                          onPressed: () =>
                              setState(() => _selectedEmployee = null),
                          tooltip: "Remove Selection",
                        ),
                        _selectedEmployee!['branch'] ?? "Main Branch",
                        _selectedEmployee!['role'] ?? "Staff",
                      ),
                    ),
                  ),
                  const Spacer(),
                ],

                if (_selectedEmployee != null) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                ],

                // ==========================================
                // 2. TRANSFER DETAILS
                // ==========================================
                Text("Transfer Details", style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),

                // inputDecorationTheme supplies fill, borders and radius.
                TextField(
                  controller: _branchNameController,
                  onChanged: _onBranchSearchChanged,
                  decoration: const InputDecoration(
                    hintText: "Select target branch...",
                    prefixIcon: Icon(Icons.business),
                  ),
                ),

                if (_branchSuggestions.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 140),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outline),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _branchSuggestions.length,
                      itemBuilder: (context, index) {
                        final name = _branchSuggestions[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on_outlined,
                            size: 20,
                          ),
                          title: Text(name),
                          onTap: () {
                            setState(() {
                              _branchNameController.text = name;
                              _branchSuggestions = [];
                            });
                          },
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                TextField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: const InputDecoration(
                    labelText: "Transfer Date",
                    prefixIcon: Icon(Icons.date_range),
                  ),
                ),

                const SizedBox(height: 30),

                // ==========================================
                // 3. ACTION
                // ==========================================
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _processTransfer,
                    child: const Text("Process Transfer"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}