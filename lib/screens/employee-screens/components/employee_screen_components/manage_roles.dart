import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:klockerapp/providers/user_provider.dart';
import '../../../../supabase/repo/supabase_service.dart';

/// What the tenant's plan allows, in the shape this screen needs.
class _PlanView {
  /// null (or empty) means the plan never loaded. Treated as "allow
  /// everything" — a failed RPC must not grey out the whole editor.
  final Set<String>? actions;

  /// Display label for the current tier.
  final String tier;

  /// action_name -> lowest tier that includes it, from plan_action_tiers().
  final Map<String, String> actionTiers;

  const _PlanView({
    required this.actions,
    required this.tier,
    required this.actionTiers,
  });

  bool get known => actions != null && actions!.isNotEmpty;

  bool allows(String action) => known ? actions!.contains(action) : true;

  /// The tier they'd need. Null when nothing is known about this action —
  /// either plan_action_tiers() failed, or the action has no
  /// feature_permissions row yet. Either way the row stays enabled.
  String? requiredTier(String action) => actionTiers[action];
}

class ManageRolesScreen extends StatefulWidget {
  const ManageRolesScreen({super.key});

  @override
  State<ManageRolesScreen> createState() => _ManageRolesScreenState();
}

class _ManageRolesScreenState extends State<ManageRolesScreen> {
  final SupabaseService _service = SupabaseService();

  static const Map<String, int> _tierRank = {
    'lite': 1,
    'basic': 2,
    'standard': 3,
    'premium': 4,
  };

  bool _isLoading = true;
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _allPermissions = [];
  Map<String, String> _actionTiers = {};

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

  String _actionOf(Map<String, dynamic> perm) =>
      perm['action_name']?.toString() ?? '';

  /// my_plan_tier() falls back to '__default__' on an unrecognised
  /// subscription_tier. The permissions are right (same set as Lite) but
  /// the label isn't something to show a customer.
  String _displayTier(String tier) => tier == '__default__' ? 'Lite' : tier;

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final perms = await _service.getAvailableAppPermissions();
      final roles = await _service.getTenantRoles();
      final tiers = await _service.getPlanActionTiers();

      if (mounted) {
        setState(() {
          _allPermissions = perms;
          _roles = roles;
          _actionTiers = tiers;
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
      // _selectedPermissionIds deliberately still contains any off-plan
      // permissions the role already had. They're inert at runtime (login
      // intersects role grants with my_plan_actions) but saving them keeps
      // the role intact through a downgrade/upgrade cycle.
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
    final user = context.watch<UserProvider>();

    final plan = _PlanView(
      actions: user.planActions,
      tier: _displayTier(user.planTier),
      actionTiers: _actionTiers,
    );

    if (_isLoading && _roles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 800;

        // If Mobile, and a role is selected, show ONLY the editor (full screen)
        if (!isWeb && _isEditing) {
          return _buildEditorPanel(isWeb, plan);
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
                    ? _buildEditorPanel(isWeb, plan)
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
  Widget _buildEditorPanel(bool isWeb, _PlanView plan) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Group permissions by their Module
    final Map<String, List<Map<String, dynamic>>> groupedPerms = {};
    for (var p in _allPermissions) {
      // A null module used to blow up the Map<String, …> key.
      final module = p['module']?.toString() ?? 'other';
      groupedPerms.putIfAbsent(module, () => []).add(p);
    }

    final hasLocked = _allPermissions.any((p) => !plan.allows(_actionOf(p)));

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

              if (hasLocked) _buildPlanBanner(theme, plan),

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
                (entry) =>
                    _buildModuleCard(theme, entry.key, entry.value, plan),
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

  Widget _buildPlanBanner(ThemeData theme, _PlanView plan) {
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            size: 20,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're on the ${plan.tier} plan",
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Greyed-out permissions belong to a higher plan. Anything "
                  "already assigned to a role stays saved and switches back "
                  "on by itself if you upgrade.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierBadge(ThemeData theme, String label, {bool emphasised = false}) {
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: emphasised ? scheme.primaryContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: emphasised
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  /// Lowest tier across a set of locked permissions — what the module
  /// header advertises.
  String? _lowestTierFor(List<Map<String, dynamic>> perms, _PlanView plan) {
    String? best;
    int bestRank = 99;
    for (final p in perms) {
      final tier = plan.requiredTier(_actionOf(p));
      if (tier == null) continue;
      final rank = _tierRank[tier.toLowerCase()] ?? 99;
      if (rank < bestRank) {
        bestRank = rank;
        best = tier;
      }
    }
    return best;
  }

  Widget _buildModuleCard(
    ThemeData theme,
    String module,
    List<Map<String, dynamic>> perms,
    _PlanView plan,
  ) {
    final scheme = theme.colorScheme;

    final locked = perms.where((p) => !plan.allows(_actionOf(p))).toList();
    final allLocked = perms.isNotEmpty && locked.length == perms.length;
    final moduleTier = allLocked ? _lowestTierFor(locked, plan) : null;

    final headerColor = allLocked ? scheme.onSurfaceVariant : scheme.onSurface;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Row(
          children: [
            if (allLocked) ...[
              Icon(Icons.lock_outline, size: 15, color: headerColor),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                module.toUpperCase(),
                style: theme.textTheme.titleSmall?.copyWith(
                  letterSpacing: 1.2,
                  color: headerColor,
                ),
              ),
            ),
            if (allLocked)
              _tierBadge(theme, moduleTier ?? 'UPGRADE', emphasised: true),
          ],
        ),
        // A module nobody can use starts collapsed — it's reference, not
        // something to scroll past on every edit.
        initiallyExpanded: !allLocked,
        // The card already draws a border; without these the tile adds its
        // own top/bottom rules when expanded.
        shape: const Border(),
        collapsedShape: const Border(),
        textColor: headerColor,
        collapsedTextColor: headerColor,
        iconColor: scheme.onSurfaceVariant,
        collapsedIconColor: scheme.onSurfaceVariant,
        children: perms.map((perm) {
          final action = _actionOf(perm);
          final isSelected = _selectedPermissionIds.contains(perm['id']);
          final description = perm['description']?.toString();
          final onPlan = plan.allows(action);
          final requiredTier = plan.requiredTier(action);

          final titleColor = onPlan ? null : scheme.onSurfaceVariant;

          // An off-plan permission that's already on the role. Worth
          // spelling out: it isn't doing anything right now, and saving
          // won't drop it.
          final strandedNote = !onPlan && isSelected
              ? "Assigned, but inactive until you upgrade"
              : null;

          return CheckboxListTile(
            enabled: onPlan,
            secondary: onPlan
                ? null
                : _tierBadge(theme, requiredTier ?? 'UPGRADE'),
            title: Text(
              action.replaceAll('_', ' ').toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(color: titleColor),
            ),
            subtitle:
                (description == null || description.isEmpty) &&
                    strandedNote == null
                ? null
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (description != null && description.isNotEmpty)
                        Text(
                          description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      if (strandedNote != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            strandedNote,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
            value: isSelected,
            onChanged: !onPlan
                ? null
                : (bool? val) {
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
