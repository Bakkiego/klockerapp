import 'package:flutter/material.dart';
import 'package:klockerapp/components/menu_expansion_tile.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import '../employee-screens/components/employee_screen_components/employee_tile.dart';

class AwardsScreen extends StatefulWidget {
  const AwardsScreen({super.key});

  @override
  State<AwardsScreen> createState() => _AwardsScreenState();
}

class _AwardsScreenState extends State<AwardsScreen> {
  String award_option_title = "Select Award Type";
  String _searchQuery = "";
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  // This would ideally fetch from your existing profiles table
  Future<void> _searchEmployees(String query) async {
    _searchQuery = query; // Added so empty state updates text correctly
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await SupabaseService().searchEmployees(query);
      setState(() => _searchResults = results);
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _assignAward(Map<String, dynamic> employee) async {
    if (award_option_title == "Select Award Type") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an award type first!")),
      );
      return;
    }

    try {
      await SupabaseService().saveAward(
        recipientProfileId: employee['id'],
        awardName: award_option_title,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Success: $award_option_title assigned to ${employee['full_name']}",
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF00A36C),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving award: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    List<MenuExpansionOBJ> awardsList = [
      MenuExpansionOBJ(
        title: 'Manager of The Year',
        onTap: () => setState(() => award_option_title = "Manager of The Year"),
      ),
      MenuExpansionOBJ(
        title: 'Employee of The Year',
        onTap: () =>
            setState(() => award_option_title = "Employee of The Year"),
      ),
      MenuExpansionOBJ(
        title: 'Cook of The Year',
        onTap: () => setState(() => award_option_title = "Cook of The Year"),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Awards'),
        elevation: 0,
        centerTitle: true,
      ),
      // 🚀 Apply Web constraints to center the content
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. AWARD SELECTION
                Text("Award Type", style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                MenuExpansionTile(
                  awardsList,
                  award_option_title,
                  Icons.workspace_premium_outlined,
                ),

                const SizedBox(height: 25),

                // 2. SEARCH BAR (Styling matched to ViewEmployee)
                Text("Search Employee", style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SearchBar(
                  elevation: WidgetStateProperty.all(0),
                  hintText: "Enter employee name...",
                  onChanged: (value) => _searchEmployees(value),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  leading: Icon(Icons.search, color: scheme.onSurfaceVariant),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: scheme.outline),
                    ),
                  ),
                  trailing: [
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 25),

                // 3. RESULTS
                Text(
                  "Search Results",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),

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

                            // 🚀 Match the cohesive Card Design from the Directory
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
                                  () {}, // Profile tap
                                  emp['full_name'] ?? "Unknown",
                                  TextButton(
                                    onPressed: () => _assignAward(emp),
                                    child: const Text("Assign"),
                                  ),
                                  emp['branch'] ?? "Main Branch",
                                  emp['role'] ?? "Staff",
                                ),
                              ),
                            );
                          },
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
