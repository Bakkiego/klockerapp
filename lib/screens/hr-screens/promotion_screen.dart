import 'package:flutter/material.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import '../employee-screens/components/employee_screen_components/employee_tile.dart';

class PromotionScreen extends StatefulWidget {
  const PromotionScreen({super.key});

  @override
  State<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends State<PromotionScreen> {
  final SupabaseService _service = SupabaseService();

  List<Map<String, dynamic>> _allEmployees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  List<String> _customJobTitles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final employees = await _service.getTenantEmployees();
      final titles = await _service.getJobTitles();

      if (mounted) {
        setState(() {
          _allEmployees = employees ?? [];
          _filteredEmployees = _allEmployees;
          _customJobTitles = titles ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Database Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterSearch(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredEmployees = _allEmployees.where((emp) {
        final name = (emp['full_name'] ?? "").toString().toLowerCase();
        return name.contains(lowerQuery);
      }).toList();
    });
  }

  void _showPromotionDialog(
    Map<String, dynamic> employee,
    String currentJobTitle,
  ) {
    String? selectedTitle;
    bool isSubmitting = false;
    final String employeeName = employee['full_name'] ?? "Employee";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text("Promote Employee"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Promoting: $employeeName",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Current: $currentJobTitle",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: "New Title",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    items: _customJobTitles
                        .map(
                          (title) => DropdownMenuItem(
                            value: title,
                            child: Text(title),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedTitle = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: (isSubmitting || selectedTitle == null)
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            await _service.updateEmployeeProfile(
                              employeeId: employee['id'],
                              updates: {'job_title': selectedTitle!},
                            );
                            if (!mounted) return;
                            Navigator.pop(context);
                            _loadEmployees();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Promotion successful!"),
                                backgroundColor: Color(0xFF00A36C),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A36C),
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Confirm"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Promotion Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                SearchBar(
                  elevation: WidgetStateProperty.all(0),
                  backgroundColor: WidgetStateProperty.all(
                    isDark ? Colors.grey[900] : Colors.white,
                  ),
                  hintText: "Search employee name...",
                  onChanged: _filterSearch,
                  leading: const Icon(Icons.search, color: Colors.grey),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  side: WidgetStateProperty.all(
                    BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00A36C),
                          ),
                        )
                      : _filteredEmployees.isEmpty
                      ? const Center(child: Text("No employees found."))
                      : ListView.builder(
                          itemCount: _filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final emp = _filteredEmployees[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[900]?.withOpacity(0.5)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                              ),
                              child: EmployeeTile(
                                () => _showPromotionDialog(
                                  emp,
                                  emp['job_title'] ?? "No Title",
                                ),
                                emp['full_name'] ?? "Unknown",
                                TextButton(
                                  onPressed: () => _showPromotionDialog(
                                    emp,
                                    emp['job_title'] ?? "No Title",
                                  ),
                                  child: const Text(
                                    "Promote",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00A36C),
                                    ),
                                  ),
                                ),
                                emp['branch'] ?? "Unassigned",
                                emp['job_title'] ?? "No Title",
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
