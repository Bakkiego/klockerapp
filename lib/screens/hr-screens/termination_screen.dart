import 'package:flutter/material.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import '../employee-screens/components/employee_screen_components/employee_tile.dart';

class TerminationScreen extends StatefulWidget {
  const TerminationScreen({super.key});

  @override
  State<TerminationScreen> createState() => _TerminationScreenState();
}

class _TerminationScreenState extends State<TerminationScreen> {
  final TextEditingController _reasonController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedEmployee;
  bool _isSearching = false;
  String _searchQuery = "";

  void _search(String query) async {
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
        // Flutter Web will crash if 'results' is null and we try to use .isEmpty on it.
        if (results == null) {
          _searchResults = [];
        } else {
          _searchResults = List<Map<String, dynamic>>.from(results);
        }
      });
    } catch (e) {
      debugPrint("Search error: $e");
      // 🚀 THE FIX: Also default to an empty list if the search throws an error
      if (mounted) setState(() => _searchResults = []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _processTermination() async {
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an employee first.")),
      );
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please provide a reason for termination."),
        ),
      );
      return;
    }

    try {
      await SupabaseService().terminateEmployee(
        employeeId: _selectedEmployee!['id'],
        reason: _reasonController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Termination Processed Successfully",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Process Termination',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
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
                    hintText: "Search employee to terminate...",
                    onChanged: _search,
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
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Search Results List
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
                                    () =>
                                        setState(() => _selectedEmployee = emp),
                                    emp['full_name'] ?? "Unknown",
                                    const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.redAccent,
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
                          ? Colors.redAccent.withOpacity(0.1)
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.3),
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
                            color: Colors.redAccent,
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
                  const Spacer(), // Pushes the rest of the form to the bottom
                ],

                if (_selectedEmployee != null) ...[
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.withOpacity(0.1)),
                  const SizedBox(height: 20),
                ],

                // ==========================================
                // 2. TERMINATION DETAILS
                // ==========================================
                Text(
                  "Termination Details",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.blueGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Termination Document",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {}, // Trigger file picker
                        icon: const Icon(
                          Icons.upload_file,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        label: const Text(
                          "Upload",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Reason for termination...",
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
                    onPressed: _processTermination,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Process Termination",
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
