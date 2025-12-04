import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: const Column(
          children: [
            Row(
              children: [
                Icon(Icons.mail, size: 50),
                SizedBox(width: 50),
                Text("Info@klockerapp.com", style: TextStyle(fontSize: 20)),
              ],
            ),
            Row(
              children: [
                Icon(Icons.phone, size: 50),
                SizedBox(width: 50),
                Text("+27 61 793 8236", style: TextStyle(fontSize: 20)),
              ],
            ),
            Row(
              children: [
                Icon(Icons.web, size: 50),
                SizedBox(width: 50),
                Text("Klockerapp.com", style: TextStyle(fontSize: 20)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
