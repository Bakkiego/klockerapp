import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart'; // 🚀 NEW: Import File Picker
import 'package:klockerapp/supabase/repo/supabase_service.dart';
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

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

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

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: Colors.orange),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
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

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error picking file: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processResignation() async {
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an employee first.")),
      );
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please provide a reason for the resignation."),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true); // Start loading spinner

    try {
      await SupabaseService().processResignation(
        employeeId: _selectedEmployee!['id'],
        resignationDate: _selectedDate,
        reason: _reasonController.text.trim(),
        fileBytes: _selectedFile?.bytes, // Pass the bytes for upload
        fileName: _selectedFile?.name, // Pass the name for storage
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Resignation & Document Processed Successfully",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted)
        setState(() => _isProcessing = false); // Stop loading spinner
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Process Resignation',
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
                    hintText: "Search employee resigning...",
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
                  // Selected Employee State
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.orange[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: EmployeeTile(
                        () {},
                        _selectedEmployee!['full_name'],
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.orange),
                          onPressed: () =>
                              setState(() => _selectedEmployee = null),
                          tooltip: "Remove Selection",
                        ),
                        _selectedEmployee!['branch'] ?? "Main Branch",
                        _selectedEmployee!['role'] ?? "Staff",
                      ),
                    ),
                  ),
                  const Spacer(),
                ],

                if (_selectedEmployee != null) ...[
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.withOpacity(0.1)),
                  const SizedBox(height: 20),
                ],

                // ==========================================
                // 2. RESIGNATION DETAILS
                // ==========================================
                Text(
                  "Resignation Details",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.blueGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: InputDecoration(
                    labelText: "Effective Date",
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.white,
                    prefixIcon: const Icon(
                      Icons.date_range,
                      color: Colors.grey,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🚀 UPGRADED: Resignation Letter Upload Area
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedFile != null
                          ? Colors.orange
                          : Colors.grey.withOpacity(0.2),
                      width: _selectedFile != null ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedFile != null
                            ? Icons.check_circle
                            : Icons.description_outlined,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Resignation Letter",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            // Show file name if selected, else show hint
                            Text(
                              _selectedFile != null
                                  ? _selectedFile!.name
                                  : "No file attached (Optional)",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                overflow: TextOverflow.ellipsis,
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
                          color: Colors.orange,
                        ),
                        label: Text(
                          _selectedFile != null ? "Change" : "Upload",
                          style: const TextStyle(
                            color: Colors.orange,
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
                    hintText:
                        "Reason for resignation (e.g., Personal, Better Offer)...",
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
                      borderSide: const BorderSide(color: Colors.orange),
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
                    onPressed: _isProcessing ? null : _processResignation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Process Resignation",
                            style: TextStyle(
                              fontSize: 16,
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
