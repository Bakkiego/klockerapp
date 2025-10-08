import 'package:flutter/material.dart';

class KTextInputField extends StatelessWidget {
  const KTextInputField({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.icon,
    this.isPassword = false, // To handle password fields
    this.controller, // To manage the field's state
  });

  final String labelText;
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Add some vertical space between fields
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword, // Hides text for passwords
        // The decoration is now centralized here
        decoration: InputDecoration(
          // The border style is inherited from your app's theme!
          // No need to define OutlineInputBorder() here anymore.
          labelText: labelText,
          hintText: hintText,
          // The icon color is inherited from your app's iconTheme
          prefixIcon: Icon(icon),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$labelText is required';
          }
          return null;
        },
      ),
    );
  }
}
