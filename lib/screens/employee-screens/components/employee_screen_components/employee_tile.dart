import 'package:flutter/material.dart';

class EmployeeTile extends StatefulWidget {
  VoidCallback onTap;
  String employeeName;
  Widget actionButton;
  EmployeeTile(this.onTap, this.employeeName, this.actionButton, {super.key});

  @override
  State<EmployeeTile> createState() => _EmployeeTileState();
}

class _EmployeeTileState extends State<EmployeeTile> {
  late String itemTitle;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: widget.onTap,
      title: Text(widget.employeeName),
      trailing: widget.actionButton,
    );
  }
}
