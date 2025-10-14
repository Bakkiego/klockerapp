import 'package:flutter/material.dart';

class KDropDownField extends StatefulWidget {
  const KDropDownField({
    super.key,
    required this.items,
    required this.hintText,
    this.onChanged,
  });

  final List<String> items;
  final String hintText;
  final void Function(String?)? onChanged;

  @override
  State<KDropDownField> createState() => _KDropDownFieldState();
}

class _KDropDownFieldState extends State<KDropDownField> {
  String? _selectedValue; // Can be null initially

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _selectedValue,
      hint: Text(widget.hintText), // Show hint text when no value is selected
      decoration: const InputDecoration(
        // Consistent styling with your text fields
        prefixIcon: Icon(Icons.location_city), // Example icon
        border: OutlineInputBorder(),
      ),
      onChanged: (String? newValue) {
        setState(() {
          _selectedValue = newValue;
        });
        if (widget.onChanged != null) {
          widget.onChanged!(newValue);
        }
      },
      items: widget.items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select an option';
        }
        return null;
      },
    );
  }
}
