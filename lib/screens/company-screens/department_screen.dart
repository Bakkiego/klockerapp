import 'package:flutter/material.dart';

// Import the necessary screens
import './components/edit_department_screen.dart';
// import 'department_detail_screen.dart'; // No longer needed if card is not tappable

class DepartmentScreen extends StatelessWidget {
  const DepartmentScreen({super.key});

  // Mock data structure for demonstration
  final List<Map<String, String>> _mockDepartments = const [
    {
      "id": "DEPT001",
      "name": "Human Resources (HR)",
      "branch": "HQ Branch",
      "code": "HR-001",
      "manager": "Sarah Connor",
    },
    {
      "id": "DEPT002",
      "name": "Finance & Accounting",
      "branch": "Downtown LA",
      "code": "FA-002",
      "manager": "John Smith",
    },
    {
      "id": "DEPT003",
      "name": "Product Development",
      "branch": "Midtown NY",
      "code": "PD-003",
      "manager": "Linda Ray",
    },
  ];

  // Helper to navigate directly to the Edit screen
  void _navigateToEditScreen(
    BuildContext context,
    Map<String, String> departmentData,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Pass the department data to the Edit screen for pre-filling
        builder: (context) =>
            EditDepartmentScreen(initialDepartmentData: departmentData),
      ),
    );
  }

  // Helper to show a simple delete confirmation
  void _showDeleteConfirmation(BuildContext context, String departmentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete the department: $departmentName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement actual delete logic
              Navigator.of(context).pop(); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$departmentName Deleted!')),
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
    return Column(
      children: [
        // Search Bar Section (Unchanged)
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SearchBar(
                  hintText: "Department Name",
                  trailing: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Department List Section (Modified)
        Expanded(
          child: ListView.builder(
            itemCount: _mockDepartments.length,
            itemBuilder: (context, index) {
              final department = _mockDepartments[index];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Card(
                  elevation: 2,
                  // 🚩 CHANGE: GestureDetector removed, Card now directly wraps ListTile
                  child: ListTile(
                    // Department Name
                    title: Text(
                      department['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    // Branch & Manager Subtitle
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Branch: ${department['branch']!}"),
                        Text("Manager: ${department['manager']!}"),
                      ],
                    ),

                    // Trailing section for Actions (Unchanged, remains functional)
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // EDIT BUTTON
                        IconButton(
                          onPressed: () =>
                              _navigateToEditScreen(context, department),
                          icon: const Icon(Icons.edit),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
