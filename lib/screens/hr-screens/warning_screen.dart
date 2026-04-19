import 'package:flutter/material.dart';
import '../employee-screens/components/employee_screen_components/employee_tile.dart';

class WarningScreen extends StatelessWidget {
  const WarningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Issue Warning'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // Prevents keyboard overflow
        padding: const EdgeInsets.all(20.0),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Find Employee",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              SearchBar(
                elevation: WidgetStateProperty.all(0),
                backgroundColor: WidgetStateProperty.all(Colors.white),
                side: WidgetStateProperty.all(
                  BorderSide(color: Colors.grey.shade300),
                ),
                hintText: "Search employee...",
                padding: WidgetStateProperty.all(
                  EdgeInsets.symmetric(horizontal: 16),
                ),
                leading: const Icon(Icons.search, color: Colors.grey),
              ),

              const SizedBox(height: 20),

              // Implementation of Warning Count UI for the demo
              Stack(
                children: [
                  EmployeeTile(
                    () {},
                    "John Doe",
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Select",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    "London Branch",
                    "Kitchen Staff",
                  ),
                  Positioned(
                    right: 80, // Positioned near the name/Select button
                    top: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color: Colors.red.shade900,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "2 Warnings", // Demo-static count
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "Warning Details",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                maxLines: 5, // Set to a fixed height for a cleaner look
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black,
                  labelText: 'Enter Warning Message',
                  hintText: 'Type detailed reason for warning...',
                  alignLabelWithHint: true, // Aligns label to top for multiline
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Final Action Button for Demo
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Warning recorded successfully"),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Issue Official Warning",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
