import 'package:flutter/material.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("System Location"),
          TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Location',
              enabled: false,
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text("Locate", style: TextStyle(fontSize: 18)),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Dark Theme"),
              Switch(value: true, onChanged: (value) {}),
            ],
          ),
          SizedBox(height: 16),
          DropdownButtonFormField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'TimeZone',
            ),
            items: [
              DropdownMenuItem(value: "SAST", child: Text("Johannesburg")),
              DropdownMenuItem(value: "UK", child: Text("UK")),
              DropdownMenuItem(value: "Pacific", child: Text("Pacific")),
            ],
            onChanged: (String? value) {},
          ),
          DropdownButtonFormField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Currency',
            ),
            items: [
              DropdownMenuItem(value: "ZAR", child: Text("R")),
              DropdownMenuItem(value: "Euro", child: Text("")),
              DropdownMenuItem(value: "USD", child: Text("")),
            ],
            onChanged: (String? value) {},
          ),
          SizedBox(height: 16),
          DropdownButtonFormField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Language',
            ),
            items: [
              DropdownMenuItem(value: "English", child: Text("ENG")),
              DropdownMenuItem(value: "French", child: Text("FR")),
              DropdownMenuItem(value: "Mandarin", child: Text("CH")),
            ],
            onChanged: (String? value) {},
          ),
        ],
      ),
    );
  }
}
