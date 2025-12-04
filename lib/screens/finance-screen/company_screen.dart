import 'package:flutter/material.dart';
import '../company-screens/department_screen.dart';
import '../company-screens/branch_screen.dart';

class CompanyScreen extends StatelessWidget {
  const CompanyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            tabs: [
              Tab(child: Text("Branch")),
              Tab(child: Text("Department")),
            ],
          ),
        ),
        body: TabBarView(children: [BranchScreen(), DepartmentScreen()]),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
