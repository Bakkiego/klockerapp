import 'package:flutter/material.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/custom_date_picker.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP DATE PICKER
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: CustomDatePicker(),
            ),

            // 2. SEARCH & FILTER HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: SearchBar(
                      elevation: WidgetStateProperty.all(0),
                      backgroundColor: WidgetStateProperty.all(
                        isDark ? Colors.grey[900] : Colors.grey[100],
                      ),
                      hintText: "Search requests...",
                      leading: const Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A36C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.filter_list_outlined,
                      color: Color(0xFF00A36C),
                    ),
                  ),
                ],
              ),
            ),

            // 3. REQUESTS LIST
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15, left: 4),
                    child: Text(
                      'Pending Requests',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Manager Review Cards
                  _buildManagerActionCard(
                    name: "Sarah Jenkins",
                    type: "Public Holiday",
                    days: "3 Days",
                    date: "Mar 15 - 18",
                    imageUrl: "https://i.pravatar.cc/150?u=1",
                  ),
                  _buildManagerActionCard(
                    name: "James Wilson",
                    type: "Maternity Leave",
                    days: "3 Days",
                    date: "Mar 15 - 18",
                    imageUrl: "https://i.pravatar.cc/150?u=2",
                  ),
                  _buildManagerActionCard(
                    name: "Leke Daniel",
                    type: "Sick Leave",
                    days: "1 Day",
                    date: "Apr 02",
                    imageUrl: "https://i.pravatar.cc/150?u=3",
                  ),
                  _buildManagerActionCard(
                    name: "Alex Carter",
                    type: "Religion Activities",
                    days: "3 Days",
                    date: "Mar 15 - 18",
                    imageUrl: "https://i.pravatar.cc/150?u=4",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerActionCard({
    required String name,
    required String type,
    required String days,
    required String date,
    required String imageUrl,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(radius: 22, backgroundImage: NetworkImage(imageUrl)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      type,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                days,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A36C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(
                date,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  child: const Text("Reject", style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A36C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("Approve", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
