import 'package:flutter/material.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import '../employee-screens/components/employee_screen_components/employee_tile.dart';

class WarningScreen extends StatefulWidget {
  const WarningScreen({super.key});

  @override
  State<WarningScreen> createState() => _WarningScreenState();
}

class _WarningScreenState extends State<WarningScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedEmployee;
  int _currentWarningCount = 0;
  bool _isSearching = false;
  String _searchQuery = "";

  void _onSearch(String query) async {
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
        // 🚀 THE FIX: Defensively protect against null responses from the database
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

  void _selectEmployee(Map<String, dynamic> emp) async {
    setState(() => _isSearching = true);
    try {
      final count = await SupabaseService().getWarningCount(emp['id']);
      setState(() {
        _selectedEmployee = emp;
        _currentWarningCount = count;
        _searchResults = [];
        _searchQuery = "";
      });
    } catch (e) {
      debugPrint("Error fetching warning count: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _submitWarning() async {
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an employee first.")),
      );
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please provide a reason for the warning."),
        ),
      );
      return;
    }

    try {
      await SupabaseService().issueWarning(
        employeeId: _selectedEmployee!['id'],
        message: _messageController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Warning recorded successfully",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error submitting warning: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to record warning: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Issue Warning',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      // 🚀 Apply Web constraints to center the content
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
                    hintText: "Search employee to warn...",
                    onChanged: _onSearch,
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
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Search Results Expanded List
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
                                    () => _selectEmployee(emp),
                                    emp['full_name'] ?? "Unknown",
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orange,
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
                  // Selected Employee State (With Integrated Badge)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: EmployeeTile(
                        () {}, // Empty tap
                        _selectedEmployee!['full_name'],
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 🚀 Integrated Warning Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "$_currentWarningCount Warnings",
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Cancel Button
                            IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.orange,
                              ),
                              onPressed: () =>
                                  setState(() => _selectedEmployee = null),
                              tooltip: "Remove Selection",
                            ),
                          ],
                        ),
                        _selectedEmployee!['branch'] ?? "Main Branch",
                        _selectedEmployee!['role'] ?? "Staff",
                      ),
                    ),
                  ),
                  const Spacer(), // Pushes the rest of the form to the bottom cleanly
                ],

                if (_selectedEmployee != null) ...[
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.withOpacity(0.1)),
                  const SizedBox(height: 20),
                ],

                // ==========================================
                // 2. WARNING DETAILS
                // ==========================================
                Text(
                  "Warning Details",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.blueGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Type detailed reason for warning...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent),
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
                    onPressed: _submitWarning,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Issue Official Warning",
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
