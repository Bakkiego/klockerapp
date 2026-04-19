import 'package:flutter/material.dart';

class KDropDownField extends StatelessWidget {
  // Changed to StatelessWidget
  const KDropDownField({
    super.key,
    required this.items,
    required this.hintText,
    this.onChanged,
    this.value, // ✅ Added to constructor properly
  });

  final List<String> items;
  final String hintText;
  final String? value; // ✅ The current selection
  final void Function(String?)? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value, // ✅ Uses the value passed from the parent
      isExpanded: true, // Prevents layout overflow
      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
      style: const TextStyle(color: Colors.white, fontSize: 16),
      // This styles the "Select Branch" text before a choice is made
      hint: Text(
        hintText,
        style: TextStyle(color: Colors.white.withOpacity(0.7)),
      ), // Ensures text isn't white!
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.location_city, color: Color(0xFF00A36C)),
        border: OutlineInputBorder(),
        // Force the dropdown background to be white so we can see the text
      ),
      dropdownColor: Colors.grey,
      onChanged: onChanged, // Passes the change straight up
      items: items.map<DropdownMenuItem<String>>((String val) {
        return DropdownMenuItem<String>(
          value: val,
          child: Text(val, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Please select an option';
        }
        return null;
      },
    );
  }
}
