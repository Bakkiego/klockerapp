import 'dart:async';

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
  bool _isProcessing = false;
  String _searchQuery = "";

  // Debounce the keystrokes, and tag each request so a slow earlier
  // response can't overwrite a newer one.
  Timer? _debounce;
  int _searchSeq = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _reasonController.dispose();
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
        // 🚀 Defensively protect against null responses from the database
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

  Future<bool> _confirmTermination() async {
    final name = _selectedEmployee?['full_name'] ?? 'This employee';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text("Terminate employee?"),
          content: Text(
            "$name will be terminated and will lose access to the app. "
            "This can't be undone from here.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Terminate"),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _processTermination() async {
    if (_selectedEmployee == null) {
      _showSnack("Please select an employee first.");
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      _showSnack("Please provide a reason for termination.");
      return;
    }

    if (!await _confirmTermination()) return;
    if (!mounted) return;

    // The button had no busy state at all — two quick taps fired two
    // terminations.
    setState(() => _isProcessing = true);

    final navigator = Navigator.of(context);

    try {
      await SupabaseService().terminateEmployee(
        employeeId: _selectedEmployee!['id'],
        reason: _reasonController.text.trim(),
      );

      if (!mounted) return;
      _showSnack("Termination processed.");
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showSnack("Error: $e", isError: true);
    }
  }

  // ==========================================
  // Build
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Process Termination')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          // Two layouts. The old single Column mixed an Expanded (search
          // list) with a Spacer (selected state) and had no scroll view, so
          // once an employee was picked the form overflowed on a phone.
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
            hintText: "Search employee to terminate...",
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
                            Icon(Icons.add_circle_outline, color: scheme.error),
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
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: EmployeeTile(
                () {}, // Empty tap
                _selectedEmployee!['full_name'],
                IconButton(
                  icon: Icon(Icons.cancel, color: scheme.onErrorContainer),
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
          // 2. TERMINATION DETAILS
          // ==========================================
          _sectionLabel(theme, "Termination Details"),
          const SizedBox(height: 8),

          // NOTE: this row is not wired up — see the chat message. The
          // Upload button has never had a handler and terminateEmployee
          // takes no file.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outline),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Termination Document",
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: null, // Not implemented yet
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text("Upload"),
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
              hintText: "Reason for termination...",
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
              onPressed: _isProcessing ? null : _processTermination,
              // Destructive, so it keeps the red — taken from the scheme
              // rather than Colors.redAccent.
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
                disabledBackgroundColor: scheme.errorContainer,
                disabledForegroundColor: scheme.onErrorContainer,
              ),
              child: _isProcessing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onError,
                      ),
                    )
                  : const Text("Process Termination"),
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
