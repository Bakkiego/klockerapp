import 'package:flutter/material.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/custom_date_picker.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/utils/leave_info_card.dart';
import '../../../../utils/custom_theme/text_theme.dart';
import 'utils/report_summary.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomDatePicker(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Leave Summary',
                style: KAppTextTheme.darkTextTheme.bodyMedium,
                textAlign: TextAlign.left,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SummaryContainer(Icons.question_answer, 20, "Leave Request"),
                SizedBox(height: 10),
                SummaryContainer(Icons.check, 5, 'Approved'),
                SizedBox(height: 10),
                SummaryContainer(Icons.close, 0, 'Rejected'),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SearchBar(
                      hintText: "Search",
                      trailing: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.search),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.filter_list_outlined, size: 35),
                ),
              ],
            ),
            SizedBox(height: 20),
            LeaveInfoCard("3 Days. Mar 15.18", "Public Holiday"),
            LeaveInfoCard("3 Days. Mar 15.18", "Public Holiday"),
            LeaveInfoCard("3 Days. Mar 15.18", "Maternity Leave"),
            LeaveInfoCard("3 Days. Mar 15.18", "Public Holiday"),
            LeaveInfoCard("3 Days. Mar 15.18", "Sick Leave"),
            LeaveInfoCard("3 Days. Mar 15.18", "Public Holiday"),
            LeaveInfoCard("3 Days. Mar 15.18", "Religion Activities"),
            LeaveInfoCard("3 Days. Mar 15.18", "Public Holiday"),
          ],
        ),
      ),
    );
  }
}
