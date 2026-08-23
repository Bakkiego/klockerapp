import 'package:flutter/material.dart';
import '../../../../models/app_enums.dart';
import 'k_dropdown_field.dart';
import 'k_text_input_field.dart';

class DataCollectorList {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final dateController = TextEditingController();

  // --- NEW: Variables to store dropdown selections ---
  String? selectedBranch;
  String? selectedDept;
  String? selectedRole;
  String? selectedJobTitle;
  List<String> jobTitleOptions = [];
  List<String> branchOptions = ["Loading..."];
  List<String> deptOptions = ["Loading..."];

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
        KTextInputField(
          controller: addressController,
          labelText: "Address",
          hintText: "Enter Employee Address",
          icon: Icons.location_on_rounded,
        ),
        KTextInputField(
          controller: phoneController,
          labelText: "Phone Number",
          hintText: "Enter Employee Phone Number",
          icon: Icons.phone,
        ),
        // Password fields...
      ],
    ),
  ];

  List<ExpansionTile> getCompanyTileBody({
    required VoidCallback onDateTap,
    required VoidCallback onRefresh,
    VoidCallback? onCreateJobTitle,
  }) {
    return [
      ExpansionTile(
        title: const Text("Company Details"),
        children: [
          KDropDownField(
            hintText: "Select Branch",
            // If your KDropDownField supports a 'value' property, add it here:
            value: selectedBranch,
            items: branchOptions,
            onChanged: (selectedValue) {
              // Now we actually save the choice!
              selectedBranch = selectedValue;
              onRefresh();
            },
          ),
          const SizedBox(height: 16),
          KDropDownField(
            hintText: "Select Department",
            items: deptOptions,
            value: selectedDept,
            onChanged: (selectedValue) {
              // Now we actually save the choice!
              selectedDept = selectedValue;
              onRefresh();
            },
          ),
          const SizedBox(height: 16),
          KDropDownField(
            hintText: "Select User Role",
            // Mapping your Enum values to a list of Strings for the UI
            items: userRole.values.map((e) => e.toSql).toList(),
            value: selectedRole,
            onChanged: (selectedValue) {
              selectedRole = selectedValue;
              onRefresh();
            },
          ),
          KDropDownField(
            hintText: "Company Job Title (e.g. Chef)",
            icon: Icons.badge_outlined,
            items: jobTitleOptions,
            value: selectedJobTitle,
            onCreateNew: onCreateJobTitle, // 🚀 NEW
            createLabel: "Create a new job title",
            onChanged: (selectedValue) {
              selectedJobTitle = selectedValue;
              onRefresh();
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: dateController,
            decoration: const InputDecoration(
              labelText: "Company Date Joining",
              prefixIcon: Icon(Icons.date_range),
            ),
            readOnly: true,
            onTap: onDateTap,
          ),
        ],
      ),
    ];
  }
}
