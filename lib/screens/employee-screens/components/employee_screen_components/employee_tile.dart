import 'package:flutter/material.dart';

class EmployeeTile extends StatelessWidget {
  final VoidCallback onTap;
  final String employeeName;
  final String employeeBranch;
  final String employeePosition;
  final String? employeeEmail; // 🚀 NEW
  final Widget actionButton;

  const EmployeeTile(
    this.onTap,
    this.employeeName,
    this.actionButton,
    this.employeeBranch,
    this.employeePosition, {
    this.employeeEmail, // 🚀 NEW
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final email = employeeEmail?.trim() ?? '';

    return ListTile(
      onTap: onTap,
      title: Text(employeeName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(employeeBranch, style: Theme.of(context).textTheme.bodySmall),
          Text(employeePosition, style: Theme.of(context).textTheme.bodySmall),
          if (email.isNotEmpty)
            Text(
              email,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: actionButton,
    );
  }
}
