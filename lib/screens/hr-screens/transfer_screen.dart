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
  // Controllers and State
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

  // --- Search Logic (With Web Null Fix) ---
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
      setState(() {
        if (results == null) {
          _searchResults = [];
        } else {
          _searchResults = List<Map<String, dynamic>>.from(results);
        }
      });
    } catch (e) {
      debugPrint("Search error: $e");
      if (mounted) setState(() => _searchResults = []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // --- Date Picker Logic ---
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF00A36C)),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  // --- Submission Logic ---
  Future<void> _processTransfer() async {
    if (_selectedEmployee == null ||
        _branchNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an employee and enter a target branch."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
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
          const SnackBar(
            content: Text(
              "Transfer successfully processed!",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Color(0xFF00A36C),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Transfer failed: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Process Transfer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      // 🚀 Apply Web constraints to center the content
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          // 🚀 REMOVED SingleChildScrollView. Now uses exact TerminationScreen layout flow!
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
                Text(
                  "Select Employee",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.blueGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                if (_selectedEmployee == null) ...[
                  SearchBar(
                    elevation: WidgetStateProperty.all(0),
                    backgroundColor: WidgetStateProperty.all(
                      isDark ? Colors.grey[900] : Colors.white,
                    ),
                    hintText: "Search employee to transfer...",
                    onChanged: _onSearchChanged,
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    leading: const Icon(Icons.search, color: Colors.grey),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                    trailing: [
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00A36C),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 🚀 EXPANDED LIST: Takes up the middle space dynamically
                  Expanded(
                    child: _searchResults.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? "Search for an employee to begin"
                                  : "No employees found",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final emp = _searchResults[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[900]?.withOpacity(0.5)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.1),
                                  ),
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
                                    const Icon(
                                      Icons.add_circle_outline,
                                      color: Color(0xFF00A36C),
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
                  // Selected Employee State
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF00A36C).withOpacity(0.1)
                          : const Color(0xFF00A36C).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF00A36C).withOpacity(0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: EmployeeTile(
                        () {}, // Empty tap
                        _selectedEmployee!['full_name'],
                        IconButton(
                          icon: const Icon(
                            Icons.cancel,
                            color: Color(0xFF00A36C),
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

                  // 🚀 SPACER: Pushes the "Transfer Details" safely to the bottom just like TerminationScreen
                  const Spacer(),
                ],

                if (_selectedEmployee != null) ...[
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.withOpacity(0.1)),
                  const SizedBox(height: 20),
                ],

                // ==========================================
                // 2. TRANSFER DETAILS
                // ==========================================
                Text(
                  "Transfer Details",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.blueGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                // Target Branch Input
                TextField(
                  controller: _branchNameController,
                  onChanged: _onBranchSearchChanged,
                  decoration: InputDecoration(
                    hintText: "Select target branch...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.white,
                    prefixIcon: const Icon(Icons.business, color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00A36C)),
                    ),
                  ),
                ),

                // Branch Suggestions Overlay
                if (_branchSuggestions.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 140,
                    ), // 🚀 Strict height so it doesn't break the layout
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
                            color: Colors.grey,
                          ),
                          title: Text(name),
                          onTap: () {
                            setState(() {
                              _branchNameController.text = name;
                              _branchSuggestions = []; // Hide suggestions
                            });
                          },
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                // Date Picker Field
                TextField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: InputDecoration(
                    labelText: "Transfer Date",
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.white,
                    prefixIcon: const Icon(
                      Icons.date_range,
                      color: Colors.grey,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00A36C)),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ==========================================
                // 3. ACTION BUTTON
                // ==========================================
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _processTransfer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A36C),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Process Transfer",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
