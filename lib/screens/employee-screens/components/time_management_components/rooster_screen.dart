import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:provider/provider.dart'; // 🚀 Added for Permissions
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 Added for Permissions

import 'manage_shifts_screen.dart';
import 'assign_screen.dart';

class ShiftDisplayClass {
  final String shiftName;
  final String time;
  final int assigneeCount;
  final Color accentColor;
  final String rawStartTime;

  ShiftDisplayClass(
    this.shiftName,
    this.time,
    this.assigneeCount,
    this.accentColor,
    this.rawStartTime,
  );
}

class RoosterScreen extends StatefulWidget {
  const RoosterScreen({super.key});

  @override
  State<RoosterScreen> createState() => _RoosterScreenState();
}

class _RoosterScreenState extends State<RoosterScreen> {
  final SupabaseService _service = SupabaseService();

  late DateTime _selectedDate;
  Map<String, Map<String, dynamic>> _templateLookup = {};
  bool _templatesLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await _service.getShiftTemplates();
      if (!mounted) return;
      setState(() {
        _templateLookup = {for (var t in templates) t['id'].toString(): t};
        _templatesLoading = false;
      });
    } catch (e) {
      debugPrint("Template Load Error: $e");
    }
  }

  Future<void> _pickDateFromCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  List<ShiftDisplayClass> _processRosterData(
    List<Map<String, dynamic>> rosterRows,
  ) {
    if (_templateLookup.isEmpty) return [];

    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var row in rosterRows) {
      final tId = row['shift_template_id'].toString();
      if (!_templateLookup.containsKey(tId)) continue;

      if (!grouped.containsKey(tId)) grouped[tId] = [];
      grouped[tId]!.add(row);
    }

    final List<ShiftDisplayClass> displayList = grouped.entries.map((entry) {
      final template = _templateLookup[entry.key];
      final name = template?['shift_name'] ?? "Unknown Shift";
      final rawStart = template?['start_time']?.toString() ?? "00:00:00";
      final start = rawStart.length >= 5 ? rawStart.substring(0, 5) : "00:00";
      final end = template?['end_time']?.toString().substring(0, 5) ?? "00:00";
      final colorHex = template?['color_hex'] ?? "#00A36C";

      return ShiftDisplayClass(
        name,
        "$start - $end",
        entry.value.length,
        Color(int.parse(colorHex.replaceAll('#', '0xFF'))),
        rawStart,
      );
    }).toList();

    displayList.sort((a, b) => a.rawStartTime.compareTo(b.rawStartTime));
    return displayList;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWeb = MediaQuery.of(context).size.width > 800;

    // 🚀 THE BOUNCER: Checking exactly what this user is allowed to do
    final userProvider = context.watch<UserProvider>();
    final canManageRosters = userProvider.can('manage_rosters');
    final canManageTemplates = userProvider.can('manage_shift_templates');

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isWeb
                    ? _buildWebDateSelector(theme)
                    : _buildMobileDateSelector(theme),

                const SizedBox(height: 20),

                // 🚀 GRANULAR UI: Only show the buttons if they have permission
                if (canManageRosters || canManageTemplates)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: isWeb
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        // 1. Assign Roster Button
                        if (canManageRosters) ...[
                          _actionBtn(
                            "Assign Roster",
                            Icons.person_add_alt_1,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AssignScreen(),
                                ),
                              );
                            },
                            isWeb: isWeb,
                          ),

                          // Add spacing only if the second button is also showing
                          if (canManageTemplates) const SizedBox(width: 16),
                        ],

                        // 2. Manage Shifts Button
                        if (canManageTemplates)
                          _actionBtn(
                            "Manage Shifts",
                            Icons.settings_outlined,
                            () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ManageShiftsScreen(),
                                ),
                              );
                              _loadTemplates();
                            },
                            isSecondary: true,
                            isWeb: isWeb,
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),
                Divider(color: Colors.grey.withOpacity(0.1)),
                const SizedBox(height: 10),

                // ==========================================
                // --- SHIFTS LIST ---
                // ==========================================
                Expanded(
                  child: _templatesLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00A36C),
                          ),
                        )
                      : StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _service.getRosterStream(_selectedDate),
                          builder: (context, snapshot) {
                            if (snapshot.hasError)
                              return Center(
                                child: Text("Error: ${snapshot.error}"),
                              );
                            if (!snapshot.hasData)
                              return const Center(
                                child: CircularProgressIndicator(),
                              );

                            final uiShifts = _processRosterData(snapshot.data!);
                            if (uiShifts.isEmpty) return _buildEmptyState();

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              itemCount: uiShifts.length,
                              itemBuilder: (context, index) => _shiftCard(
                                uiShifts[index],
                                index == uiShifts.length - 1,
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

  // 🚀 WEB HEADER UI
  Widget _buildWebDateSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.only(top: 30, left: 16, right: 16, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 28),
                onPressed: () => setState(
                  () => _selectedDate = _selectedDate.subtract(
                    const Duration(days: 1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickDateFromCalendar,
                icon: const Icon(Icons.calendar_month, size: 18),
                label: const Text(
                  "Jump to Date",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00A36C),
                  side: const BorderSide(color: Color(0xFF00A36C)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 28),
                onPressed: () => setState(
                  () => _selectedDate = _selectedDate.add(
                    const Duration(days: 1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📱 MOBILE HEADER UI
  Widget _buildMobileDateSelector(ThemeData theme) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: theme.colorScheme.surface,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: DatePicker(
          DateTime.now().subtract(const Duration(days: 3)),
          width: 60,
          height: 90,
          initialSelectedDate: _selectedDate,
          onDateChange: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
          selectionColor: const Color(0xFF00A36C),
          selectedTextColor: Colors.white,
          dateTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  // Action Button Helper (Adapts width for Web)
  Widget _actionBtn(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isSecondary = false,
    required bool isWeb,
  }) {
    Widget btn = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSecondary ? Colors.transparent : const Color(0xFF00A36C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00A36C)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSecondary ? const Color(0xFF00A36C) : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSecondary ? const Color(0xFF00A36C) : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    // On Web, fix the width so they don't stretch. On Mobile, use Expanded.
    if (isWeb) {
      return SizedBox(width: 160, child: btn);
    }
    return Expanded(child: btn);
  }

  // Shift Card UI
  Widget _shiftCard(ShiftDisplayClass shift, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Text(
              shift.time.split(" ")[0],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Container(
              width: 2,
              height: 80,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: isLast ? Colors.transparent : Colors.grey.withOpacity(0.3),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                ),
              ],
              border: Border(
                left: BorderSide(color: shift.accentColor, width: 4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shift.shiftName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${shift.assigneeCount} Employees",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  shift.time,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 64,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            "No shifts scheduled for this day",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
