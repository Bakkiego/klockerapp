import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';

class AssetManagementScreen extends StatefulWidget {
  const AssetManagementScreen({super.key});

  @override
  State<AssetManagementScreen> createState() => _AssetManagementScreenState();
}

class _AssetManagementScreenState extends State<AssetManagementScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _tenantId;

  List<Map<String, dynamic>> _assets = [];
  List<Map<String, dynamic>> _employees = [];

  // The predefined status list
  final List<String> _statusOptions = [
    'New',
    'Fairly New',
    'Used',
    'Fairly Used',
    'Old',
    'Broken',
  ];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      final profileData = await _supabase
          .from('profiles')
          .select('tenant_id')
          .eq('id', currentUserId)
          .single();

      _tenantId = profileData['tenant_id'];

      if (_tenantId != null) {
        // Fetch employees for assignment dropdown
        final employeeResponse = await _supabase
            .from('profiles')
            .select('id, full_name, avatar_url')
            .eq('tenant_id', _tenantId as Object)
            .order('full_name');

        _employees = List<Map<String, dynamic>>.from(employeeResponse);

        // Fetch the assets
        await _fetchAssets();
      }
    } catch (e) {
      debugPrint("Error loading assets: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAssets() async {
    if (_tenantId == null) return;
    try {
      final data = await SupabaseService().getCompanyAssets(_tenantId!);
      if (mounted) setState(() => _assets = data);
    } catch (e) {
      debugPrint("Error refreshing assets: $e");
    }
  }

  Future<void> _deleteAsset(String assetId) async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService().deleteAsset(assetId);
      await _fetchAssets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Asset Deleted"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // --- ADD / EDIT ASSET DIALOG ---
  // ==========================================
  void _showAssetDialog({Map<String, dynamic>? existingAsset}) {
    final nameController = TextEditingController(text: existingAsset?['name']);
    final descController = TextEditingController(
      text: existingAsset?['description'],
    );

    String selectedStatus = existingAsset?['status'] ?? 'New';
    String? selectedEmployeeId = existingAsset?['assigned_to'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          existingAsset == null
                              ? "Add New Asset"
                              : "Edit Asset",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ASSET NAME
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: "Asset Name (e.g. MacBook Pro)",
                            prefixIcon: Icon(Icons.devices),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ASSET STATUS
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Condition / Status",
                            prefixIcon: Icon(Icons.health_and_safety),
                          ),
                          value: selectedStatus,
                          items: _statusOptions.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null)
                              setDialogState(() => selectedStatus = val);
                          },
                        ),
                        const SizedBox(height: 16),

                        // ASSIGNED TO
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Assigned To (Optional)",
                            prefixIcon: Icon(Icons.person),
                          ),
                          value: selectedEmployeeId,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text("Unassigned"),
                            ),
                            ..._employees.map((emp) {
                              return DropdownMenuItem<String>(
                                value: emp['id'],
                                child: Text(emp['full_name'] ?? 'Unknown'),
                              );
                            }),
                          ],
                          onChanged: (val) =>
                              setDialogState(() => selectedEmployeeId = val),
                        ),
                        const SizedBox(height: 16),

                        // DESCRIPTION / SERIAL NUMBER
                        TextField(
                          controller: descController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: "Notes / Serial Number",
                            prefixIcon: Icon(Icons.notes),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // SUBMIT & CANCEL
                        // SUBMIT & CANCEL BUTTONS
                        Row(
                          children: [
                            Expanded(
                              flex: 1, // Keep cancel button small
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text("Cancel"),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12), // Slightly smaller gap
                            Expanded(
                              flex: 2, // Give the main action more room
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: const Color(0xFF00A36C),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  // ... (Keep your onPressed logic exactly the same here) ...
                                },
                                // 🚀 WRAPPED IN FITTEDBOX TO PREVENT OVERFLOW
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Assign Training",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // --- UI BUILDER ---
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Asset Management",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchAssets().then((_) => setState(() => _isLoading = false));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showAssetDialog(), // Null means ADD
        backgroundColor: const Color(0xFF00A36C),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Asset",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : _assets.isEmpty
          ? _buildEmptyState()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: RefreshIndicator(
                  onRefresh: _fetchAssets,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWeb ? 0 : 16,
                      vertical: 24,
                    ),
                    itemCount: _assets.length,
                    itemBuilder: (context, index) {
                      final asset = _assets[index];

                      final name = asset['name'] ?? 'Unknown Asset';
                      final status = asset['status'] ?? 'New';
                      final desc = asset['description'] ?? '';
                      final assignedName =
                          asset['assigned_to_profile']?['full_name'] ??
                          'Unassigned';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Left side Icon
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.devices_other,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Middle Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _buildStatusBadge(status),
                                        const SizedBox(width: 8),
                                        if (desc.isNotEmpty)
                                          Expanded(
                                            child: Text(
                                              desc,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.person_outline,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          assignedName,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Right side actions
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blueAccent,
                                    ),
                                    onPressed: () =>
                                        _showAssetDialog(existingAsset: asset),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text("Delete Asset?"),
                                          content: Text(
                                            "Are you sure you want to delete '$name'?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text("Cancel"),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                _deleteAsset(asset['id']);
                                              },
                                              child: const Text("Delete"),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Assets Managed",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Add your company laptops, phones, and equipment here.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'New':
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      case 'Fairly New':
        bgColor = Colors.teal.withOpacity(0.1);
        textColor = Colors.teal;
        break;
      case 'Used':
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blueAccent;
        break;
      case 'Fairly Used':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      case 'Old':
        bgColor = Colors.deepOrange.withOpacity(0.1);
        textColor = Colors.deepOrange;
        break;
      case 'Broken':
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
