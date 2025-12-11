import 'package:flutter/material.dart';

class EmployeeTile extends StatefulWidget {
  VoidCallback onTap;
  String employeeName;
  String employeeBranch;
  String employeePosition;
  Widget actionButton;
  EmployeeTile(
    this.onTap,
    this.employeeName,
    this.actionButton,
    this.employeeBranch,
    this.employeePosition, {
    super.key,
  });

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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.employeeBranch,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            widget.employeePosition,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: widget.actionButton,
    );
  }
}
