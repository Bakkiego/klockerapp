import 'package:flutter/material.dart';

class LeaveInfoCard extends StatelessWidget {
  LeaveInfoCard(this.leaveDate, this.leaveTitle);

  final String leaveTitle;
  final String leaveDate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(leaveTitle),
                const SizedBox(width: 10),
                Text(
                  leaveDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.close),
                SizedBox(width: 16),
                Icon(Icons.check),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
