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

  /// Call from the owning State's dispose(). Seven controllers were being
  /// created per screen and never released.
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    dateController.dispose();
  }

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

    /// Enum role values (as toSql strings) to leave out of the User Role
    /// dropdown — used for the admin/manager seat cap. Compared
    /// case-insensitively. Pass `roleNotice` alongside it, or an admin
    /// just finds two options missing with no explanation.
    Set<String> blockedRoles = const {},

    /// Rendered directly above the User Role dropdown. This is where the
    /// seat-cap message belongs: next to the control it affects, not in a
    /// different card further down the form.
    Widget? roleNotice,
  }) {
    final blocked = blockedRoles.map((r) => r.toLowerCase()).toSet();

    final roleItems = userRole.values
        .map((e) => e.toSql)
        .where(
          // The current value must always stay in the list. A
          // DropdownButton whose `value` has no matching item throws,
          // so filtering out the role someone already holds would crash
          // the screen rather than restrict it.
          (r) => r == selectedRole || !blocked.contains(r.toLowerCase()),
        )
        .toList();

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
          if (roleNotice != null) roleNotice,
          KDropDownField(
            hintText: "Select User Role",
            // Mapping your Enum values to a list of Strings for the UI
            items: roleItems,
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
