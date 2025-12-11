import 'package:flutter/material.dart';
import '../company-screens/department_screen.dart';
import '../company-screens/branch_screen.dart';
import './components/add_branch_screen.dart';
import './components/add_department_screen.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize the TabController with a length of 2 (Branch and Department)
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Logic for the Floating Action Button ---
  void _handleFabPress() {
    final currentIndex = _tabController.index;

    // Check the index of the currently selected tab
    if (currentIndex == 0) {
      // 0 is the Branch tab
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddBranchScreen()),
      );
    } else if (currentIndex == 1) {
      // 1 is the Department tab
      // TODO: Uncomment and replace with your actual AddDepartmentScreen() when ready
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddDepartmentScreen()),
      );
      print(
        "FAB pressed on Department tab - TODO: Navigate to AddDepartmentScreen",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController, // Attach controller to TabBar
          tabs: const [
            Tab(child: Text("Branch")),
            Tab(child: Text("Department")),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController, // Attach controller to TabBarView
        children: const [BranchScreen(), DepartmentScreen()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleFabPress, // Call our logic function
        child: const Icon(Icons.add),
      ),
    );
  }
}
