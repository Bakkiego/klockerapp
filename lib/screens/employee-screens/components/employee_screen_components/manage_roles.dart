import 'package:flutter/material.dart';
import '../../../../supabase/repo/supabase_service.dart';

class ManageRolesScreen extends StatefulWidget {
  const ManageRolesScreen({super.key});

  @override
  State<ManageRolesScreen> createState() => _ManageRolesScreenState();
}

class _ManageRolesScreenState extends State<ManageRolesScreen> {
  final SupabaseService _service = SupabaseService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _allPermissions = [];

  // 🚀 FIXED: We now use a strict flag to keep the editor open!
  bool _isEditing = false;

  // State for the Right Panel (Detail View)
  Map<String, dynamic>? _selectedRole;
  final TextEditingController _nameController = TextEditingController();
  Set<String> _selectedPermissionIds = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final perms = await _service.getAvailableAppPermissions();
      final roles = await _service.getTenantRoles();

      if (mounted) {
        setState(() {
          _allPermissions = perms;
          _roles = roles;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading role data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectRole(Map<String, dynamic>? role) {
    setState(() {
      _isEditing = true; // 🚀 Forces the editor to stay on screen
      _selectedRole = role;

      if (role == null) {
        // Creating a new role
        _nameController.clear();
        _selectedPermissionIds = {};
      } else {
        // Editing an existing role
        _nameController.text = role['role_name'];
        _selectedPermissionIds = (role['role_permissions'] as List)
            .map((p) => p['permission_id'] as String)
            .toSet();
      }
    });
  }

  void _closeEditor() {
    setState(() {
      _isEditing = false;
      _selectedRole = null;
      _nameController.clear();
      _selectedPermissionIds = {};
    });
  }

  Future<void> _saveCurrentRole() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Role name cannot be empty"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.saveRoleWithPermissions(
        roleId: _selectedRole?['id'],
        roleName: _nameController.text,
        permissionIds: _selectedPermissionIds.toList(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Role saved successfully!"),
          backgroundColor: Color(0xFF00A36C),
        ),
      );

      _closeEditor(); // 🚀 Safely close the panel after saving
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving role: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteRole(String roleId, String roleName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Role?"),
        content: Text(
          "Are you sure you want to delete '$roleName'? Employees with this role will lose their special access.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await _service.deleteUnifiedRole(roleId);
      if (_selectedRole?['id'] == roleId) _closeEditor();
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _roles.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00A36C)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 800;

        // If Mobile, and a role is selected, show ONLY the editor (full screen)
        if (!isWeb && _isEditing) {
          return _buildEditorPanel(isWeb);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT PANEL: The List of Roles
            Expanded(
              flex: 1,
              child: Container(
                decoration: isWeb
                    ? BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                      )
                    : null,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: const Color(0xFF00A36C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _selectRole(null),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          "Create New Role",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _roles.isEmpty
                          ? const Center(
                              child: Text(
                                "No custom roles created yet.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _roles.length,
                              itemBuilder: (context, index) {
                                final role = _roles[index];
                                final isSelected =
                                    _selectedRole?['id'] == role['id'];
                                final permCount =
                                    (role['role_permissions'] as List).length;

                                return Container(
                                  color: isSelected
                                      ? const Color(
                                          0xFF00A36C,
                                        ).withOpacity(0.05)
                                      : Colors.transparent,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isSelected
                                          ? const Color(0xFF00A36C)
                                          : Colors.grey.shade200,
                                      child: Icon(
                                        Icons.badge,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey,
                                        size: 18,
                                      ),
                                    ),
                                    title: Text(
                                      role['role_name'],
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text("$permCount Permissions"),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      onPressed: () => _deleteRole(
                                        role['id'],
                                        role['role_name'],
                                      ),
                                    ),
                                    onTap: () => _selectRole(role),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // RIGHT PANEL: The Editor
            if (isWeb)
              Expanded(
                flex: 2,
                child: _isEditing
                    ? _buildEditorPanel(isWeb)
                    : const Center(
                        child: Text(
                          "Select a role or create a new one.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
              ),
          ],
        );
      },
    );
  }

  // THE EDITOR UI
  Widget _buildEditorPanel(bool isWeb) {
    // Group permissions by their Module
    final Map<String, List<Map<String, dynamic>>> groupedPerms = {};
    for (var p in _allPermissions) {
      groupedPerms.putIfAbsent(p['module'], () => []).add(p);
    }

    return Column(
      children: [
        // Mobile Back Button
        if (!isWeb)
          AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _closeEditor,
            ),
            title: Text(_selectedRole == null ? "New Role" : "Edit Role"),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Text(
                _selectedRole == null
                    ? "Create Custom Role"
                    : "Edit Role Configuration",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Job Title / Role Name (e.g., Shift Supervisor)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                "Assign Permissions",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),

              // The grouped toggle switches
              ...groupedPerms.entries.map((entry) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    initiallyExpanded: true,
                    children: entry.value.map((perm) {
                      final isSelected = _selectedPermissionIds.contains(
                        perm['id'],
                      );
                      return CheckboxListTile(
                        activeColor: const Color(0xFF00A36C),
                        title: Text(
                          perm['action_name']
                              .toString()
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          perm['description'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        value: isSelected,
                        onChanged: (bool? val) {
                          setState(() {
                            if (val == true) {
                              _selectedPermissionIds.add(perm['id']);
                            } else {
                              _selectedPermissionIds.remove(perm['id']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        // Bottom Action Buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _closeEditor,
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF00A36C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveCurrentRole,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Save Configurations",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
