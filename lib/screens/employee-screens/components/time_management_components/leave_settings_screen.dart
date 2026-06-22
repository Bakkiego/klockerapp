import 'package:flutter/material.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart'; // Ensure this path is correct

class LeaveSettingsScreen extends StatefulWidget {
  const LeaveSettingsScreen({super.key});

  @override
  State<LeaveSettingsScreen> createState() => _LeaveSettingsScreenState();
}

class _LeaveSettingsScreenState extends State<LeaveSettingsScreen> {
  List<Map<String, dynamic>> _leavePolicies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPolicies();
  }

  Future<void> _fetchPolicies() async {
    setState(() => _isLoading = true);
    try {
      final policies = await SupabaseService().getLeavePolicies();
      if (mounted) {
        setState(() {
          _leavePolicies = policies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching policies: $e");
    }
  }

  void _showAddPolicyDialog([Map<String, dynamic>? existingPolicy]) {
    final isEditing = existingPolicy != null;
    final nameController = TextEditingController(
      text: isEditing ? existingPolicy['leave_type'] : '',
    );
    final daysController = TextEditingController(
      text: isEditing ? existingPolicy['entitled_days'].toString() : '',
    );

    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? "Edit Leave Policy" : "New Leave Category",
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Category Name (e.g., Study Leave)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: daysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Entitled Days per Year",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (nameController.text.isNotEmpty &&
                              daysController.text.isNotEmpty) {
                            setDialogState(() => isSubmitting = true);
                            try {
                              final days = int.parse(daysController.text);
                              if (isEditing) {
                                await SupabaseService().updateLeavePolicy(
                                  id: existingPolicy['id'],
                                  leaveType: nameController.text,
                                  entitledDays: days,
                                );
                              } else {
                                await SupabaseService().addLeavePolicy(
                                  leaveType: nameController.text,
                                  entitledDays: days,
                                );
                              }
                              if (mounted) {
                                Navigator.pop(context);
                                _fetchPolicies(); // Refresh the list
                              }
                            } catch (e) {
                              setDialogState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A36C),
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isEditing ? "Save Changes" : "Create Category"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deletePolicy(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Delete Policy"),
        content: const Text(
          "Are you sure you want to delete this leave category?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await SupabaseService().deleteLeavePolicy(id);
        _fetchPolicies();
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error deleting: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Leave Policies",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "Company Allowances",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Define the types of leave and the total days employees are entitled to per year. These limits will apply to all employees.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 24),

                if (_leavePolicies.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        "No leave policies set.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),

                ..._leavePolicies.map((policy) {
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: const Color(
                          0xFF00A36C,
                        ).withOpacity(0.1),
                        child: const Icon(
                          Icons.beach_access,
                          color: Color(0xFF00A36C),
                        ),
                      ),
                      title: Text(
                        policy['leave_type'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text("${policy['entitled_days']} Days / Year"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showAddPolicyDialog(policy),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deletePolicy(policy['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPolicyDialog(),
        backgroundColor: const Color(0xFF00A36C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("New Category"),
      ),
    );
  }
}
