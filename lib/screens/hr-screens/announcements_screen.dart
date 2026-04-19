import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klockerapp/screens/employee-screens/components/employee_screen_components/k_text_input_field.dart';
import '../employee-screens/components/employee_screen_components/data_collector_list.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final DataCollectorList dataCollectorList = DataCollectorList();

  // Separate controllers for Start and End dates to prevent them from mirroring each other
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Post Announcement'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Announcement Content",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            KTextInputField(
              labelText: "Title",
              hintText: "e.g., Office Holiday Notice",
              icon: Icons.campaign_rounded,
            ),
            const SizedBox(height: 15),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Description",
                hintText: "Enter the full announcement details...",
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Schedule Duration",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startDateController,
                    readOnly: true,
                    onTap: () => _selectDate(_startDateController),
                    decoration: InputDecoration(
                      labelText: "Start Date",
                      prefixIcon: const Icon(Icons.calendar_today, size: 18),
                      filled: true,
                      fillColor: Colors.black,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _endDateController,
                    readOnly: true,
                    onTap: () => _selectDate(_endDateController),
                    decoration: InputDecoration(
                      labelText: "End Date",
                      prefixIcon: const Icon(Icons.event_available, size: 18),
                      filled: true,
                      fillColor: Colors.black,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Announcement Published!"),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.blueAccent,
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text(
                  "Publish Announcement",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
