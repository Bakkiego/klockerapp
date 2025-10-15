import 'package:flutter/material.dart';

class EmployeeTile extends StatefulWidget {
  late VoidCallback onTap;
  EmployeeTile(this.onTap);

  @override
  State<EmployeeTile> createState() => _EmployeeTileState();
}

class _EmployeeTileState extends State<EmployeeTile> {
  late String itemTitle;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => (),
      title: Text("John"),
      trailing: Row(
        mainAxisSize: MainAxisSize
            .min, // Prevents the Row from taking all available space
        children: const [
          Icon(Icons.edit_outlined), // First icon (e.g., Edit)
          SizedBox(width: 8), // Add some space between icons
          Icon(Icons.delete_outline, color: Colors.red),
        ],
      ),
    );
  }
}
