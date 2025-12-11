import 'package:flutter/material.dart';

// Import the Edit Department Screen to navigate there
import 'edit_department_screen.dart';

class DepartmentDetailScreen extends StatelessWidget {
  // Receives the data map from the Department List Screen
  final Map<String, String> departmentDetails;

  const DepartmentDetailScreen({super.key, required this.departmentDetails});

  // Helper to navigate to the Edit screen
  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Pass the details to the Edit screen for pre-filling
        builder: (context) =>
            EditDepartmentScreen(initialDepartmentData: departmentDetails),
      ),
    );
  }

  // Helper to show the delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Department Deletion'),
        content: Text(
          'Are you sure you want to delete the department: ${departmentDetails['name']}? This action is permanent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement actual department deletion logic
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to the list screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Department Deleted!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme's primary color for icons/accents
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(departmentDetails['name'] ?? 'Department Details'),
        actions: [
          // Edit Button in AppBar
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _navigateToEdit(context),
          ),
          // Delete Button in AppBar
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. Department Header Card ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.apartment, size: 40, color: primaryColor),
                    const SizedBox(height: 10),
                    Text(
                      departmentDetails['name'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code: ${departmentDetails['code'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- 2. Manager and Location Section ---
            const Text(
              'Organizational Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            _buildDetailRow(
              icon: Icons.person_outline,
              label: 'Assigned Manager',
              value: departmentDetails['manager'] ?? 'Unassigned',
            ),

            _buildDetailRow(
              icon: Icons.location_city,
              label: 'Branch Location',
              value: departmentDetails['branch'] ?? 'N/A',
            ),

            _buildDetailRow(
              icon: Icons.perm_identity,
              label: 'Department ID',
              value: departmentDetails['id'] ?? 'N/A',
            ),

            const SizedBox(height: 32),

            // Optional: Quick actions related to the department (e.g., View Employees)
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement navigation to a list of employees in this department
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Viewing Employees for this Department...'),
                  ),
                );
              },
              icon: const Icon(Icons.group_outlined),
              label: const Text('View Employees'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable widget to display a single detail row with an icon
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
