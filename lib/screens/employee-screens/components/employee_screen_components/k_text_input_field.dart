import 'package:flutter/material.dart';

class KTextInputField extends StatefulWidget {
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
  State<KTextInputField> createState() => _KTextInputFieldState();
}

class _KTextInputFieldState extends State<KTextInputField> {
  late final String _branch;
  @override
  Widget build(BuildContext context) {
    return Padding(
      // Add some vertical space between fields
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword, // Hides text for passwords
        // The decoration is now centralized here
        decoration: InputDecoration(
          // The border style is inherited from your app's theme!
          // No need to define OutlineInputBorder() here anymore.
          labelText: widget.labelText,
          hintText: widget.hintText,
          // The icon color is inherited from your app's iconTheme
          prefixIcon: Icon(widget.icon),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '${widget.labelText} is required';
          }
          return null;
        },
      ),
    );
  }
}
