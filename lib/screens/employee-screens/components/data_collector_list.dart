import 'package:flutter/material.dart';
import 'k_dropdown_field.dart';
import 'k_text_input_field.dart';
// You can remove 'dart:ffi', it's not being used.

// CHANGE: This class now accepts a function parameter in a method
class DataCollectorList {
  final formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController =
      TextEditingController(); // Create separate controllers
  final confirmPasswordController = TextEditingController(); // for each field

  // Controller for the date text field
  final dateController = TextEditingController();

  // This list defines the structure for personal details
  late final List<ExpansionTile> personalTileBody = [
    ExpansionTile(
      title: const Text("Personal Details"),
      children: [
        KTextInputField(
          controller: nameController,
          labelText: "Name",
          hintText: "Enter Employee Name",
          icon: Icons.person,
        ),
        // ... other fields ...
        KTextInputField(
          controller: passwordController,
          labelText: "Password",
          hintText: "Enter Employee Password",
          icon: Icons.password,
          isPassword: true,
        ),
        KTextInputField(
          controller: confirmPasswordController,
          labelText: "Confirm Password",
          hintText: "Confirm Password",
          icon: Icons.password,
          isPassword: true,
        ),
      ],
    ),
  ];

  // CHANGE: This is now a method that takes the onTap function as an argument
  List<ExpansionTile> getCompanyTileBody({required VoidCallback onDateTap}) {
    return [
      ExpansionTile(
        title: const Text("Company Details"),
        children: [
          KDropDownField(
            hintText: "Select Branch",
            items: const ["Main Branch", "Downtown Office", "Warehouse"],
            onChanged: (selectedValue) {},
          ),
          const SizedBox(height: 16),
          KDropDownField(
            hintText: "Select Department",
            items: const ["HR", "Engineering", "Sales"],
            onChanged: (selectedValue) {},
          ),
          const SizedBox(height: 16),
          // This TextField now gets its onTap from the outside
          TextField(
            controller: dateController, // Use a controller to display the date
            decoration: const InputDecoration(
              labelText: "Company Date Joining",
              prefixIcon: Icon(Icons.date_range),
            ),
            readOnly: true,
            onTap: onDateTap, // Use the function passed from the outside
          ),
        ],
      ),
    ];
  }
}
