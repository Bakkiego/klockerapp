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

class AttendanceSpecifics extends StatefulWidget {
  const AttendanceSpecifics({super.key});

  @override
  State<AttendanceSpecifics> createState() => _AttendanceSpecificsState();
}

class _AttendanceSpecificsState extends State<AttendanceSpecifics> {
  @override
  final List<EmployeeAttendance> attendanceList = [
    EmployeeAttendance("09:00", "17:00", "John Doe", "Present"),
    EmployeeAttendance("08:30", "16:45", "Jane Smith", "Late"),
    EmployeeAttendance("09:15", "17:30", "Bob Johnson", "Absent"),
    EmployeeAttendance("08:00", "16:00", "Alice Brown", "Present"),
  ];
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: attendanceList.length,
      itemBuilder: (context, index) {
        final record = attendanceList[index];
        return Card(
          elevation: 2,
          margin: EdgeInsetsGeometry.symmetric(vertical: 6.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(attendanceList[index].status),
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              record.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'In: ${record.clockInTime}, Out: ${record.clockOutTime}',
            ),
            trailing: Text('Status: ${record.status}'),
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
