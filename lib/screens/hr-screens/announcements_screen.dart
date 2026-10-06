import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:klockerapp/screens/employee-screens/components/employee_screen_components/k_text_input_field.dart';
import 'package:klockerapp/utils/custom_theme/k_palette.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final SupabaseService _service = SupabaseService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  static final DateFormat _dbDate = DateFormat('yyyy-MM-dd');

  bool _isPublishing = false;

  // --- Branch Selection State ---
  List<Map<String, dynamic>> _branches = [];
  String? _selectedBranchId; // null means "All Branches"
  bool _isLoadingBranches = true;

  @override
  void initState() {
    super.initState();
    _fetchBranches(); // Load branches when screen opens
  }

  // --- Fetch Branches Method ---
  Future<void> _fetchBranches() async {
    try {
      final data = await _service.getBranches();

      if (mounted) {
        setState(() {
          _branches = data;
          _isLoadingBranches = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching branches: $e");
      if (mounted) setState(() => _isLoadingBranches = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  // ==========================================
  // Helpers
  // ==========================================

  void _showSnack(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Default snackBarTheme handles the normal case. Only failures override
    // the colour — and a null style lets the theme's contentTextStyle win.
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

  /// Opens the picker seeded with whatever is already in the field, so
  /// re-picking doesn't jump back to today.
  Future<void> _selectDate(
    TextEditingController controller, {
    DateTime? notBefore,
  }) async {
    final lower = notBefore ?? DateTime(2000);
    final existing = DateTime.tryParse(controller.text);

    var initial = existing ?? DateTime.now();
    if (initial.isBefore(lower)) initial = lower;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: lower,
      lastDate: DateTime(2100),
      // No `builder:` override — datePickerTheme in k_theme.dart styles
      // this in both modes. The old override forced light-mode defaults.
    );

    if (pickedDate == null || !mounted) return;
    setState(() => controller.text = _dbDate.format(pickedDate));
  }

  Future<void> _handlePublish() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final startDate = _startDateController.text.trim();
    final endDate = _endDateController.text.trim();

    if (title.isEmpty ||
        description.isEmpty ||
        startDate.isEmpty ||
        endDate.isEmpty) {
      _showSnack("Please fill in all fields before publishing.");
      return;
    }

    final start = DateTime.tryParse(startDate);
    final end = DateTime.tryParse(endDate);

    if (start == null || end == null) {
      _showSnack("Those dates didn't read correctly — please pick them again.");
      return;
    }

    if (end.isBefore(start)) {
      _showSnack("The end date can't be before the start date.");
      return;
    }

    setState(() => _isPublishing = true);

    // Captured before the await: after the pop below, `context` no longer
    // has a messenger or navigator to look up.
    final navigator = Navigator.of(context);

    try {
      await _service.createAnnouncement(
        title: title,
        content: description,
        branchId:
            _selectedBranchId, // passes selected branch OR null for company-wide
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;

      _showSnack("Announcement published.");
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      _showSnack("Database Error: $e", isError: true);
      // Only reset here. On success the screen is gone, so calling
      // setState in a `finally` would touch a disposed State.
      setState(() => _isPublishing = false);
    }
  }

  // ==========================================
  // Build
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Post Announcement')),
      // 🚀 Apply Web constraints to center the content
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 24.0,
              left: 20.0,
              right: 20.0,
              bottom: 40.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // 1. TARGET AUDIENCE
                // ==========================================
                _sectionLabel("Target Audience"),

                if (_isLoadingBranches)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  DropdownButtonFormField<String?>(
                    value: _selectedBranchId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Select Branch",
                      prefixIcon: Icon(Icons.store_mall_directory_outlined),
                    ),
                    dropdownColor: scheme.surface,
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            "All Branches (Company-Wide)",
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.brandText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      ..._branches.map(
                        (branch) => DropdownMenuItem(
                          value: branch['id'].toString(),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              branch['name'].toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedBranchId = value),
                  ),

                const SizedBox(height: 30),

                // ==========================================
                // 2. ANNOUNCEMENT CONTENT
                // ==========================================
                _sectionLabel("Announcement Content"),

                // KTextInputField kept for the title
                KTextInputField(
                  labelText: "Title",
                  hintText: "e.g., Office Holiday Notice",
                  icon: Icons.campaign_rounded,
                  controller: _titleController,
                ),
                const SizedBox(height: 16),

                // Unified Description Field
                TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    hintText: "Enter the full announcement details...",
                  ),
                ),

                const SizedBox(height: 30),

                // ==========================================
                // 3. SCHEDULE DURATION
                // ==========================================
                _sectionLabel("Schedule Duration"),

                Row(
                  children: [
                    Expanded(
                      child: _dateField(
                        controller: _startDateController,
                        label: "Start Date",
                        icon: Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dateField(
                        controller: _endDateController,
                        label: "End Date",
                        icon: Icons.event_available,
                        // Can't end before it starts.
                        notBefore: DateTime.tryParse(
                          _startDateController.text.trim(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // ==========================================
                // 4. ACTION BUTTON
                // ==========================================
                SizedBox(
                  width: double.infinity,
                  height: 55, // 🚀 Standardized height
                  child: ElevatedButton.icon(
                    onPressed: _isPublishing ? null : _handlePublish,
                    icon: _isPublishing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isPublishing ? "Publishing..." : "Publish Announcement",
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

  /// Small bold caption above each group of fields.
  Widget _sectionLabel(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Read-only field that opens a date picker on tap.
  Widget _dateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    DateTime? notBefore,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectDate(controller, notBefore: notBefore),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }
}
