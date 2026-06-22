import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:klockerapp/screens/employee-screens/components/employee_screen_components/k_text_input_field.dart';

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

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
        controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields before publishing."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Announcement Published!",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFF00A36C),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Database Error: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post Announcement',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
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
                Text(
                  "Target Audience",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.blueGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                _isLoadingBranches
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00A36C),
                          ),
                        ),
                      )
                    : DropdownButtonFormField<String?>(
                        value: _selectedBranchId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: "Select Branch",
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(
                            Icons.store_mall_directory_outlined,
                            color: Colors.grey,
                          ),
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
                            borderSide: const BorderSide(
                              color: Color(0xFF00A36C),
                            ),
                          ),
                        ),
                        dropdownColor: isDark ? Colors.grey[850] : Colors.white,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                "All Branches (Company-Wide)",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00A36C),
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
                Text(
                  "Announcement Content",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.blueGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

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
                  decoration: InputDecoration(
                    labelText: "Description",
                    labelStyle: const TextStyle(color: Colors.grey),
                    hintText: "Enter the full announcement details...",
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
                      borderSide: const BorderSide(color: Color(0xFF00A36C)),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ==========================================
                // 3. SCHEDULE DURATION
                // ==========================================
                Text(
                  "Schedule Duration",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.blueGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startDateController,
                        readOnly: true,
                        onTap: () => _selectDate(_startDateController),
                        decoration: InputDecoration(
                          labelText: "Start Date",
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.grey,
                          ),
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
                            borderSide: const BorderSide(
                              color: Color(0xFF00A36C),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _endDateController,
                        readOnly: true,
                        onTap: () => _selectDate(_endDateController),
                        decoration: InputDecoration(
                          labelText: "End Date",
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(
                            Icons.event_available,
                            size: 18,
                            color: Colors.grey,
                          ),
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
                            borderSide: const BorderSide(
                              color: Color(0xFF00A36C),
                            ),
                          ),
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
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isPublishing ? "Publishing..." : "Publish Announcement",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A36C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
