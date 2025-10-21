import 'package:flutter/material.dart';
import 'package:klockerapp/utils/custom_theme/text_theme.dart';

class AttendanceSummary extends StatefulWidget {
  const AttendanceSummary({super.key});

  @override
  State<AttendanceSummary> createState() => _AttendanceSummaryState();
}

class _AttendanceSummaryState extends State<AttendanceSummary> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Attendance Summary',
            style: KAppTextTheme.darkTextTheme.bodyMedium,
            textAlign: TextAlign.left,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            spacing: 20,
            children: [
              SummaryContainer(Icons.document_scanner_sharp, 20, "Present"),
              SummaryContainer(Icons.assignment_late, 5, 'Late'),
              SummaryContainer(Icons.no_accounts, 0, 'Absent'),
            ],
          ),
        ),
      ],
    );
  }
}

class SummaryContainer extends StatelessWidget {
  SummaryContainer(
    @required this.sumIcon,
    @required this.sumValue,
    @required this.sumTitle,
  );

  late String sumTitle;
  late int sumValue;
  late IconData sumIcon;

  late String sumValueString = sumValue.toString();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.lightGreenAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      width: 105,
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: Colors.green,
              child: Icon(sumIcon),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 10.0),
            child: Text(
              sumTitle,
              style: TextStyle(color: Colors.black, fontFamily: 'Poppins'),
              textAlign: TextAlign.left,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Text(
              sumValueString,
              style: TextStyle(color: Colors.black, fontFamily: 'Poppins'),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
