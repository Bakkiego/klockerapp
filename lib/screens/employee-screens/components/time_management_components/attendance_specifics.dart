import 'package:flutter/material.dart';

class EmployeeAttendance {
  late final String clockInTime;
  late final String clockOutTime;
  late final String name;
  late final String status;

  EmployeeAttendance(
    @required this.clockInTime,
    @required this.clockOutTime,
    @required this.name,
    @required this.status,
  );
}

class AttendanceSpecifics extends StatelessWidget {
  final List<EmployeeAttendance> attendanceList = [
    EmployeeAttendance("09:00", "17:00", "John Doe", "Present"),
    EmployeeAttendance("08:30", "16:45", "Jane Smith", "Late"),
    EmployeeAttendance("09:15", "17:30", "Bob Johnson", "Absent"),
    EmployeeAttendance("08:00", "16:00", "Alice Brown", "Present"),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: attendanceList.length,
      itemBuilder: (context, index) {
        final record = attendanceList[index];
        final statusColor = _getStatusColor(record.status);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            // color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.15),
              child: Text(
                record.name[0],
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              record.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "${record.clockInTime} - ${record.clockOutTime}",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                record.status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Color _getStatusColor(String status) {
  switch (status) {
    case 'Present':
      return Colors.green.shade600;
    case 'Late':
      return Colors.orange.shade700;
    case 'Absent':
      return Colors.red.shade600;
    default:
      return Colors.grey;
  }
}
