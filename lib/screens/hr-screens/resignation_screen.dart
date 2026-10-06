import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart'; // 🚀 NEW: Import File Picker
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import '../../utils/custom_theme/k_palette.dart';
import '../employee-screens/components/employee_screen_components/employee_tile.dart';

class ResignationScreen extends StatefulWidget {
  const ResignationScreen({super.key});

  @override
  State<ResignationScreen> createState() => _ResignationScreenState();
}

class _ResignationScreenState extends State<ResignationScreen> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedEmployee;
  bool _isSearching = false;
  bool _isProcessing = false; // 🚀 NEW: Loading state for the upload
  String _searchQuery = "";
  DateTime _selectedDate = DateTime.now();

  // 🚀 NEW: File Storage variables
  PlatformFile? _selectedFile;

  // Search plumbing: debounce the keystrokes, and tag each request so a slow
  // earlier response can't overwrite a newer one.
  Timer? _debounce;
  int _searchSeq = 0;

  static final DateFormat _dbDate = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _dateController.text = _dbDate.format(_selectedDate);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _reasonController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // ==========================================
  // Helpers
  // ==========================================

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: isError
              ? theme.textTheme.bodyMedium?.copyWith(color: scheme.onError)
              : null,
        ),
        backgroundColor: isError ? scheme.error : null,
      ),
    );
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    setState(() => _searchQuery = query);

    if (query.trim().isEmpty) {
      _searchSeq++; // invalidate anything in flight
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _runSearch(query),
    );
  }

  Future<void> _runSearch(String query) async {
    final seq = ++_searchSeq;
    try {
      final dynamic results = await SupabaseService().searchEmployees(query);
      // A newer keystroke already fired — drop this result.
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _searchResults = results == null
            ? []
            : List<Map<String, dynamic>>.from(results);
      });
    } catch (e) {
      debugPrint("Search error: $e");
      if (!mounted || seq != _searchSeq) return;
      setState(() => _searchResults = []);
    } finally {
      if (mounted && seq == _searchSeq) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      // No `builder:` override — datePickerTheme handles both modes. The old
      // one forced an orange primary into a light-mode scheme.
    );

    if (pickedDate == null || !mounted) return;
    setState(() {
      _selectedDate = pickedDate;
      _dateController.text = _dbDate.format(_selectedDate);
    });
  }

  // 🚀 NEW: Method to pick documents safely on Web & Mobile
  // 🚀 UPDATED: Removed '.platform' to match your working AddTicketScreen
  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
        withData:
            true, // Keep this as true! It loads the file bytes into memory for the web upload
      );

      if (result == null || !mounted) return;
      setState(() => _selectedFile = result.files.first);
    } catch (e) {
      _showSnack("Error picking file: $e", isError: true);
    }
  }

  Future<bool> _confirmResignation() async {
    final name = _selectedEmployee?['full_name'] ?? 'This employee';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Process resignation?"),
        content: Text(
          "$name will be marked as resigned effective "
          "${_dateController.text}. This can't be undone from here.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _processResignation() async {
    if (_selectedEmployee == null) {
      _showSnack("Please select an employee first.");
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      _showSnack("Please provide a reason for the resignation.");
      return;
    }

    if (!await _confirmResignation()) return;
    if (!mounted) return;

    setState(() => _isProcessing = true); // Start loading spinner

    // Captured before the await — after the pop, `context` has no navigator.
    final navigator = Navigator.of(context);

    try {
      await SupabaseService().processResignation(
        employeeId: _selectedEmployee!['id'],
        resignationDate: _selectedDate,
        reason: _reasonController.text.trim(),
        fileBytes: _selectedFile?.bytes, // Pass the bytes for upload
        fileName: _selectedFile?.name, // Pass the name for storage
      );

      if (!mounted) return;
      _showSnack("Resignation processed.");
      navigator.pop();
    } catch (e) {
      debugPrint("Error: $e");
      if (!mounted) return;
      _showSnack("Error: $e", isError: true);
      // Reset only on failure — on success this screen is already gone.
      setState(() => _isProcessing = false);
    }
  }

  // ==========================================
  // Build
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Process Resignation')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          // Two distinct layouts. The old single Column mixed an Expanded
          // (search list) with a Spacer (selected state) and had no scroll
          // view, so once an employee was picked the form overflowed on a
          // phone.
          child: _selectedEmployee == null
              ? _buildSearchStep()
              : _buildDetailsStep(),
        ),
      ),
    );
  }

  Widget _buildSearchStep() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
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
          _sectionLabel(theme, "Select Employee"),
          const SizedBox(height: 8),

          SearchBar(
            hintText: "Search employee resigning...",
            onChanged: _onSearchChanged,
            leading: const Icon(Icons.search),
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
          const SizedBox(height: 10),

          // Search Results List
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.trim().isEmpty
                          ? "Search for an employee to begin"
                          : _isSearching
                          ? "Searching..."
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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: EmployeeTile(
                            () => setState(() => _selectedEmployee = emp),
                            emp['full_name'] ?? "Unknown",
                            Icon(
                              Icons.add_circle_outline,
                              color: context.status.pendingFg,
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
    );
  }

  Widget _buildDetailsStep() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final caution = context.status;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: 24.0,
        left: 20.0,
        right: 20.0,
        bottom: 32.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(theme, "Select Employee"),
          const SizedBox(height: 8),

          // Selected Employee State
          Container(
            decoration: BoxDecoration(
              color: caution.pendingBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: EmployeeTile(
                () {},
                _selectedEmployee!['full_name'],
                IconButton(
                  icon: Icon(Icons.cancel, color: caution.pendingFg),
                  onPressed: () => setState(() => _selectedEmployee = null),
                  tooltip: "Remove Selection",
                ),
                _selectedEmployee!['branch'] ?? "Main Branch",
                _selectedEmployee!['role'] ?? "Staff",
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),

          // ==========================================
          // 2. RESIGNATION DETAILS
          // ==========================================
          _sectionLabel(theme, "Resignation Details"),
          const SizedBox(height: 8),

          TextField(
            controller: _dateController,
            readOnly: true,
            onTap: _selectDate,
            decoration: const InputDecoration(
              labelText: "Effective Date",
              prefixIcon: Icon(Icons.date_range),
            ),
          ),

          const SizedBox(height: 16),

          // 🚀 UPGRADED: Resignation Letter Upload Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedFile != null
                    ? caution.pendingFg
                    : scheme.outline,
                width: _selectedFile != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedFile != null
                      ? Icons.check_circle
                      : Icons.description_outlined,
                  color: _selectedFile != null
                      ? caution.pendingFg
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Resignation Letter",
                        style: theme.textTheme.titleSmall,
                      ),
                      // Show file name if selected, else show hint
                      Text(
                        _selectedFile?.name ?? "No file attached (Optional)",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickDocument,
                  icon: Icon(
                    _selectedFile != null
                        ? Icons.change_circle
                        : Icons.upload_file,
                    size: 18,
                  ),
                  label: Text(_selectedFile != null ? "Change" : "Upload"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Reason",
              hintText:
                  "Reason for resignation (e.g., Personal, Better Offer)...",
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
              onPressed: _isProcessing ? null : _processResignation,
              child: _isProcessing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : const Text("Process Resignation"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) => Text(
    text,
    style: theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );
}
