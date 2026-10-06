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

  @override
  void dispose() {
    _nameController.dispose();
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

  /// `role_permissions` comes back null for a role saved with none, which
  /// made `as List` throw while building the list.
  List<dynamic> _permsOf(Map<String, dynamic> role) =>
      (role['role_permissions'] as List?) ?? const [];

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final perms = await _service.getAvailableAppPermissions();
      final roles = await _service.getTenantRoles();

      if (mounted) {
        setState(() {
          _allPermissions = perms;
          _roles = roles;
        });
      }
    } catch (e) {
      debugPrint("Error loading role data: $e");
      _showSnack("Couldn't load roles: $e", isError: true);
    } finally {
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
        _nameController.text = role['role_name']?.toString() ?? '';
        _selectedPermissionIds = _permsOf(
          role,
        ).map((p) => p['permission_id'] as String).toSet();
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
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showSnack("Role name cannot be empty", isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.saveRoleWithPermissions(
        roleId: _selectedRole?['id'],
        roleName: name, // was the raw, untrimmed field value
        permissionIds: _selectedPermissionIds.toList(),
      );

      if (!mounted) return;
      _showSnack("Role saved.");
      setState(() => _isSaving = false);
      _closeEditor(); // 🚀 Safely close the panel after saving
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack("Error saving role: $e", isError: true);
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await _service.deleteUnifiedRole(roleId);
      if (!mounted) return;
      if (_selectedRole?['id'] == roleId) _closeEditor();
      await _loadData();
    } catch (e) {
      // Was unguarded: a failed delete left _isLoading stuck true and
      // _loadData was never reached, so the list silently stopped updating.
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack("Couldn't delete the role: $e", isError: true);
    }
  }

  // ==========================================
  // Build
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_isLoading && _roles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
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
                          right: BorderSide(color: scheme.outline),
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
                        ),
                        onPressed: () => _selectRole(null),
                        icon: const Icon(Icons.add),
                        label: const Text("Create New Role"),
                      ),
                    ),
                    Expanded(
                      child: _roles.isEmpty
                          ? Center(
                              child: Text(
                                "No custom roles created yet.",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _roles.length,
                              itemBuilder: (context, index) =>
                                  _buildRoleTile(theme, _roles[index]),
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
                    : Center(
                        child: Text(
                          "Select a role or create a new one.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRoleTile(ThemeData theme, Map<String, dynamic> role) {
    final scheme = theme.colorScheme;
    final isSelected = _selectedRole?['id'] == role['id'];
    final permCount = _permsOf(role).length;

    return Container(
      color: isSelected ? scheme.primaryContainer : Colors.transparent,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? scheme.primary
              : scheme.surfaceContainer,
          child: Icon(
            Icons.badge,
            color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
            size: 18,
          ),
        ),
        title: Text(
          role['role_name']?.toString() ?? 'Unnamed role',
          style: isSelected
              ? theme.textTheme.titleSmall
              : theme.textTheme.bodyLarge,
        ),
        subtitle: Text(
          permCount == 1 ? "1 Permission" : "$permCount Permissions",
        ),
        trailing: IconButton(
          tooltip: "Delete role",
          icon: Icon(Icons.delete_outline, color: scheme.error, size: 20),
          onPressed: () => _deleteRole(
            role['id'],
            role['role_name']?.toString() ?? 'this role',
          ),
        ),
        onTap: () => _selectRole(role),
      ),
    );
  }

  // THE EDITOR UI
  Widget _buildEditorPanel(bool isWeb) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Group permissions by their Module
    final Map<String, List<Map<String, dynamic>>> groupedPerms = {};
    for (var p in _allPermissions) {
      // A null module used to blow up the Map<String, …> key.
      final module = p['module']?.toString() ?? 'other';
      groupedPerms.putIfAbsent(module, () => []).add(p);
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
            backgroundColor: Colors.transparent,
            centerTitle: false,
          ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Text(
                _selectedRole == null
                    ? "Create Custom Role"
                    : "Edit Role Configuration",
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: "Job Title / Role Name (e.g., Shift Supervisor)",
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                "Assign Permissions",
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),

              if (groupedPerms.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    "No permissions are defined for this app yet.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),

              // The grouped toggle switches
              ...groupedPerms.entries.map(
                (entry) => _buildModuleCard(theme, entry.key, entry.value),
              ),
            ],
          ),
        ),

        // Bottom Action Buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outline)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _closeEditor,
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveCurrentRole,
                    child: _isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimary,
                            ),
                          )
                        : const Text("Save Configurations"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModuleCard(
    ThemeData theme,
    String module,
    List<Map<String, dynamic>> perms,
  ) {
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          module.toUpperCase(),
          style: theme.textTheme.titleSmall?.copyWith(letterSpacing: 1.2),
        ),
        initiallyExpanded: true,
        // The card already draws a border; without these the tile adds its
        // own top/bottom rules when expanded.
        shape: const Border(),
        collapsedShape: const Border(),
        textColor: scheme.onSurface,
        collapsedTextColor: scheme.onSurface,
        iconColor: scheme.onSurfaceVariant,
        collapsedIconColor: scheme.onSurfaceVariant,
        children: perms.map((perm) {
          final isSelected = _selectedPermissionIds.contains(perm['id']);
          final description = perm['description']?.toString();

          return CheckboxListTile(
            title: Text(
              perm['action_name'].toString().replaceAll('_', ' ').toUpperCase(),
              style: theme.textTheme.labelLarge,
            ),
            subtitle: description == null || description.isEmpty
                ? null
                : Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
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
  }
}
