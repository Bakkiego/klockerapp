import 'package:flutter/material.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:klockerapp/screens/company-screens/components/add_branch_screen.dart';
import 'package:klockerapp/screens/company-screens/components/edit_branch_screen.dart';
import 'package:provider/provider.dart'; // 🚀 Added for Permissions
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 Added for Permissions

class BranchScreen extends StatefulWidget {
  const BranchScreen({super.key});

  @override
  State<BranchScreen> createState() => _BranchScreenState();
}

class _BranchScreenState extends State<BranchScreen> {
  List<Map<String, dynamic>> _branches = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getAdminBranches();
      if (mounted) {
        setState(() {
          _branches = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 THE BOUNCER: Check if they are actually allowed to manage branches
    final userProvider = context.watch<UserProvider>();
    final canManageBranches = userProvider.can('manage_branches');

    final filteredBranches = _branches
        .where(
          (b) => b['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,

      // 🚀 GRANULAR SECURITY: Hide the Add button if they lack permission
      floatingActionButton: canManageBranches
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddBranchScreen(),
                  ),
                ).then((_) => _fetchBranches());
              },
              backgroundColor: const Color(0xFF00A36C),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Add Branch",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null, // Return null to completely hide the FAB

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              hintText: "Search Branches...",
              elevation: WidgetStateProperty.all(1),
              onChanged: (value) => setState(() => _searchQuery = value),
              leading: const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A36C)),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchBranches,
                    color: const Color(0xFF00A36C),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filteredBranches.length,
                      itemBuilder: (context, index) {
                        final branch = filteredBranches[index];
                        final bool hasLocation = branch['gps_lat'] != null;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 6.0,
                          ),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: hasLocation
                                    ? const Color(0xFF00A36C).withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                child: Icon(
                                  hasLocation
                                      ? Icons.location_on
                                      : Icons.location_off,
                                  color: hasLocation
                                      ? const Color(0xFF00A36C)
                                      : Colors.orange,
                                ),
                              ),
                              title: Text(
                                branch['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                hasLocation
                                    ? "Geofence Active"
                                    : "Location Not Set",
                                style: TextStyle(
                                  color: hasLocation
                                      ? Colors.green
                                      : Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                              // 🚀 GRANULAR SECURITY: Hide the Edit icon if they lack permission
                              trailing: canManageBranches
                                  ? IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditBranchScreen(
                                                  initialBranchData:
                                                      Map<String, String>.from(
                                                        branch.map(
                                                          (
                                                            key,
                                                            value,
                                                          ) => MapEntry(
                                                            key,
                                                            value?.toString() ??
                                                                "",
                                                          ),
                                                        ),
                                                      ),
                                                ),
                                          ),
                                        ).then((_) => _fetchBranches());
                                      },
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : null, // Return null to remove the trailing icon entirely
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
