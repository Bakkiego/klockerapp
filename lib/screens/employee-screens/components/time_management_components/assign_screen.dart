import 'package:flutter/material.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import '../time_management_components/utils/multi_select_calendar.dart';
import 'go/assign_go_locations_screen.dart';

enum _LocationMode { branch, go }

class AssignScreen extends StatefulWidget {
  const AssignScreen({super.key});

  @override
  State<AssignScreen> createState() => _AssignScreenState();
}

class _AssignScreenState extends State<AssignScreen> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _templates = [];

  List<DateTime> _bulkAssignmentDates = [];
  List<String> _selectedEmployeeIds = [];
  String? _selectedBranchId;
  String? _selectedTemplateId;

  _LocationMode _mode = _LocationMode.branch;
  List<Map<String, dynamic>> _selectedGoLocations = [];

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
      debugPrint('Load Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickGoLocations() async {
    final result = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (_) => AssignGoLocationsScreen(
          initiallySelected: _selectedGoLocations,
        ),
      ),
    );
    if (result != null) {
      setState(() => _selectedGoLocations = result);
    }
  }

  Future<void> _handleBulkSave() async {
    if (_selectedEmployeeIds.isEmpty ||
        _selectedTemplateId == null ||
        _bulkAssignmentDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Missing selection: Ensure dates, employees, and shift template are selected.',
          ),
        ),
      );
      return;
    }

    if (_mode == _LocationMode.branch && _selectedBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a branch location.')),
      );
      return;
    }

    if (_mode == _LocationMode.go && _selectedGoLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one GO location.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_mode == _LocationMode.branch) {
        await _service.assignBulkShifts(
          employeeIds: _selectedEmployeeIds,
          branchId: _selectedBranchId!,
          templateId: _selectedTemplateId!,
          dates: _bulkAssignmentDates,
        );
      } else {
        await _service.assignGoShifts(
          employeeIds: _selectedEmployeeIds,
          templateId: _selectedTemplateId!,
          dates: _bulkAssignmentDates,
          locationIds:
              _selectedGoLocations.map((l) => l['id'].toString()).toList(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                  _buildSectionHeader(
                    '1. Select Dates',
                    '${_bulkAssignmentDates.length} selected',
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

                  _buildSectionHeader(
                    '2. Select Employees',
                    '${_selectedEmployeeIds.length} selected',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search employees...',
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

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDropdown(
                          label: 'Select Shift Template',
                          value: _selectedTemplateId,
                          items: _templates.map((t) {
                            final color = Color(
                              int.parse(
                                t['color_hex'].replaceAll('#', '0xFF'),
                              ),
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
                        const SizedBox(height: 16),
                        const Text(
                          'Work location mode',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<_LocationMode>(
                          segments: const [
                            ButtonSegment(
                              value: _LocationMode.branch,
                              label: Text('Branch'),
                              icon: Icon(Icons.store_mall_directory_outlined),
                            ),
                            ButtonSegment(
                              value: _LocationMode.go,
                              label: Text('Klocker GO'),
                              icon: Icon(Icons.route_outlined),
                            ),
                          ],
                          selected: {_mode},
                          onSelectionChanged: (set) {
                            setState(() {
                              _mode = set.first;
                              if (_mode == _LocationMode.branch) {
                                _selectedGoLocations = [];
                              } else {
                                _selectedBranchId = null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_mode == _LocationMode.branch)
                          _buildDropdown(
                            label: 'Select Work Location (Branch)',
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
                          )
                        else
                          _buildGoLocationField(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

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
                                'SAVE ASSIGNMENTS',
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

  Widget _buildGoLocationField() {
    final label = _selectedGoLocations.isEmpty
        ? 'Enter Location to search'
        : _selectedGoLocations.map((l) => l['name']).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Work Location (Klocker GO)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickGoLocations,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.transparent,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: _selectedGoLocations.isEmpty
                    ? Colors.grey
                    : Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (_selectedGoLocations.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedGoLocations
                .map(
                  (l) => Chip(
                    label: Text(l['name']?.toString() ?? ''),
                    onDeleted: () {
                      setState(() {
                        _selectedGoLocations.removeWhere(
                          (x) => x['id'] == l['id'],
                        );
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ],
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
