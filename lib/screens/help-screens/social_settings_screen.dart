import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialSettingsScreen extends StatelessWidget {
  const SocialSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.google, size: 30),
              Text("oogle"),
              SizedBox(width: 150),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: const BorderSide(color: Colors.green, width: 1.0),
                  ),
                ),
                onPressed: () {},
                child: Text("Sign in", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          Row(
            children: [
              FaIcon(FontAwesomeIcons.video, size: 30),
              const SizedBox(width: 20),
              Text("Zoom"),
              SizedBox(width: 125),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: const BorderSide(color: Colors.green, width: 1.0),
                  ),
                ),
                onPressed: () {},
                child: Text("Sign in", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
