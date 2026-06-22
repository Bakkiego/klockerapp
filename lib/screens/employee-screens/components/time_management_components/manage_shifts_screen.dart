import 'package:flutter/material.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ManageShiftsScreen extends StatefulWidget {
  const ManageShiftsScreen({super.key});

  @override
  State<ManageShiftsScreen> createState() => _ManageShiftsScreenState();
}

class _ManageShiftsScreenState extends State<ManageShiftsScreen> {
  List<Map<String, dynamic>> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getShiftTemplates();
      setState(() {
        _templates = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error fetching shifts: $e")));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTemplate(String id) async {
    try {
      await SupabaseService().deleteShiftTemplate(id);
      _fetchTemplates();
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Shifts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showShiftDialog(),
        backgroundColor: const Color(0xFF00A36C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : _templates.isEmpty
          ? const Center(child: Text("No shifts created yet."))
          : RefreshIndicator(
              onRefresh: _fetchTemplates,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _templates.length,
                itemBuilder: (context, index) {
                  final shift = _templates[index];
                  return _buildManageCard(shift);
                },
              ),
            ),
    );
  }

  Widget _buildManageCard(Map<String, dynamic> shift) {
    final String id = shift['id'];
    final String name = shift['shift_name'];
    final String range =
        "${shift['start_time'].toString().substring(0, 5)} - ${shift['end_time'].toString().substring(0, 5)}";
    final String colorHex = shift['color_hex'] ?? '#00A36C';

    // Parse hex string back to Flutter Color
    final Color accentColor = Color(
      int.parse(colorHex.replaceAll('#', '0xFF')),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 45,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(range, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            onPressed: () => _showShiftDialog(template: shift),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteTemplate(id),
          ),
        ],
      ),
    );
  }

  void _showShiftDialog({Map<String, dynamic>? template}) {
    final bool isEditing = template != null;
    final nameController = TextEditingController(
      text: isEditing ? template['shift_name'] : "",
    );

    // Parse color and time from template or use defaults
    Color pickerColor = isEditing
        ? Color(int.parse(template['color_hex'].replaceAll('#', '0xFF')))
        : const Color(0xFF00A36C);

    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    if (isEditing) {
      final startParts = template['start_time'].split(':');
      final endParts = template['end_time'].split(':');
      startTime = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );
      endTime = TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditing ? "Edit Shift Template" : "Create Shift Template",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              // Color Picker Tile
              ListTile(
                title: const Text("Shift Color"),
                trailing: CircleAvatar(
                  backgroundColor: pickerColor,
                  radius: 15,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Pick a color'),
                      content: SingleChildScrollView(
                        child: BlockPicker(
                          pickerColor: pickerColor,
                          onColorChanged: (color) {
                            setModalState(() => pickerColor = color);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Shift Name (e.g. Morning)",
                ),
              ),
              ListTile(
                title: const Text("Start Time"),
                trailing: Text(startTime.format(context)),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (t != null) setModalState(() => startTime = t);
                },
              ),
              ListTile(
                title: const Text("End Time"),
                trailing: Text(endTime.format(context)),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                  );
                  if (t != null) setModalState(() => endTime = t);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A36C),
                  ),
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      String formatTime(TimeOfDay t) =>
                          "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00";

                      String colorToHex(Color c) =>
                          '#${c.value.toRadixString(16).substring(2).toUpperCase()}';

                      if (isEditing) {
                        await SupabaseService().updateShiftTemplate(
                          id: template['id'],
                          shiftName: nameController.text,
                          startTime: formatTime(startTime),
                          endTime: formatTime(endTime),
                          colorHex: colorToHex(pickerColor),
                        );
                      } else {
                        await SupabaseService().createShiftTemplate(
                          shiftName: nameController.text,
                          startTime: formatTime(startTime),
                          endTime: formatTime(endTime),
                          colorHex: colorToHex(pickerColor),
                        );
                      }
                      if (mounted) Navigator.pop(context);
                      _fetchTemplates();
                    }
                  },
                  child: Text(
                    isEditing ? "UPDATE TEMPLATE" : "CREATE TEMPLATE",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
