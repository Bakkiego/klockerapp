import 'package:flutter/material.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import '../time_management_components/utils/multi_select_calendar.dart';

class AssignScreen extends StatefulWidget {
  const AssignScreen({super.key});

  @override
  State<AssignScreen> createState() => _AssignScreenState();
}

class _AssignScreenState extends State<AssignScreen> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  // Data from Supabase
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _templates = [];

  // Selections
  List<DateTime> _bulkAssignmentDates = [];
  List<String> _selectedEmployeeIds = [];
  String? _selectedBranchId;
  String? _selectedTemplateId;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEmployees = _employees.where((emp) {
        final name = emp['full_name'].toString().toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  Future<void> _loadAllData() async {
    try {
      final results = await Future.wait([
        _service.getEmployees(),
        _service.getBranches(),
        _service.getShiftTemplates(),
      ]);

      setState(() {
        _employees = results[0];
        _filteredEmployees = results[0];
        _branches = results[1];
        _templates = results[2];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Load Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBulkSave() async {
    if (_selectedEmployeeIds.isEmpty ||
        _selectedBranchId == null ||
        _selectedTemplateId == null ||
        _bulkAssignmentDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Missing selection: Ensure dates, employees, shift, and branch are selected.",
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _service.assignBulkShifts(
        employeeIds: _selectedEmployeeIds,
        branchId: _selectedBranchId!,
        templateId: _selectedTemplateId!,
        dates: _bulkAssignmentDates,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Assignment successful!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shift Assignment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SECTION 1: CALENDAR
                  _buildSectionHeader(
                    "1. Select Dates",
                    "${_bulkAssignmentDates.length} selected",
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: MultiSelectCalendar(
                        initialSelectedDates: _bulkAssignmentDates,
                        highlightColor: const Color(0xFF00A36C),
                        onDatesChanged: (newDates) =>
                            setState(() => _bulkAssignmentDates = newDates),
                      ),
                    ),
                  ),

                  const Divider(height: 40, thickness: 1),

                  // SECTION 2: EMPLOYEES
                  _buildSectionHeader(
                    "2. Select Employees",
                    "${_selectedEmployeeIds.length} selected",
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Search employees...",
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.transparent,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListView.separated(
                            itemCount: _filteredEmployees.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final emp = _filteredEmployees[index];
                              final isSelected = _selectedEmployeeIds.contains(
                                emp['id'],
                              );
                              return ListTile(
                                dense: true,
                                title: Text(
                                  emp['full_name'],
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                trailing: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: isSelected
                                      ? const Color(0xFF00A36C)
                                      : Colors.grey,
                                ),
                                onTap: () {
                                  setState(() {
                                    isSelected
                                        ? _selectedEmployeeIds.remove(emp['id'])
                                        : _selectedEmployeeIds.add(emp['id']);
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // SECTION 3: SHIFT & BRANCH
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildDropdown(
                          label: "Select Shift Template",
                          value: _selectedTemplateId,
                          items: _templates.map((t) {
                            final color = Color(
                              int.parse(t['color_hex'].replaceAll('#', '0xFF')),
                            );
                            return DropdownMenuItem(
                              value: t['id'] as String,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: color,
                                    radius: 6,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(t['shift_name']),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedTemplateId = val),
                        ),
                        const SizedBox(height: 15),
                        _buildDropdown(
                          label: "Select Work Location (Branch)",
                          value: _selectedBranchId,
                          items: _branches
                              .map(
                                (b) => DropdownMenuItem(
                                  value: b['id'] as String,
                                  child: Text(b['name']),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedBranchId = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // SAVE BUTTON
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A36C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isSaving ? null : _handleBulkSave,
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "SAVE ASSIGNMENTS",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, String trailing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            trailing,
            style: const TextStyle(
              color: Color(0xFF00A36C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ],
    );
  }
}
