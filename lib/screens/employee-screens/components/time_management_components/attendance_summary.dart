import 'package:flutter/material.dart';
import 'package:klockerapp/utils/custom_theme/text_theme.dart';
import 'utils/report_summary.dart';

class AttendanceSummary extends StatelessWidget {
  const AttendanceSummary({super.key});

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
          child: Wrap(
            spacing: 5,
            runSpacing: 12.0,
            alignment: WrapAlignment.spaceEvenly,
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
