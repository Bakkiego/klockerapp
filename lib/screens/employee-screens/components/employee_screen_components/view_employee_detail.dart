import 'package:flutter/material.dart';

class ViewEmployeeScreen extends StatelessWidget {
  final Map<String, dynamic> employee;

  const ViewEmployeeScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(employee['full_name'] ?? 'Employee Profile')),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 20),
          Text(
            employee['full_name'] ?? 'N/A',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 40, indent: 20, endIndent: 20),

          _infoTile(Icons.email, "Email", employee['email']),
          _infoTile(Icons.phone, "Phone", employee['phone_num']?.toString()),
          _infoTile(Icons.location_city, "Branch", employee['branch']),
          _infoTile(Icons.work, "Department", employee['dept_name']),
          _infoTile(Icons.badge, "Role", employee['role']),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String? value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00A36C)),
      title: Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      subtitle: Text(
        value ?? 'Not Assigned',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
