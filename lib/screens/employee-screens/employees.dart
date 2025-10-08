import 'package:flutter/material.dart';
import 'components/add_employee.dart';
import 'components/view_employee.dart';
import 'components/edit_employee.dart';

class Employees extends StatelessWidget {
  const Employees({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Employees'),
          bottom: const TabBar(
            tabs: [
              Tab(child: Text("Employees")),
              Tab(child: Text("Add")),
              Tab(child: Text("Edit")),
            ],
          ),
        ),
        body: TabBarView(
          children: [ViewEmployee(), AddEmployee(), EditEmployee()],
        ),
      ),
    );
  }
}
