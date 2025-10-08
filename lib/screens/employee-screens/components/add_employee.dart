import 'package:flutter/material.dart';
// Import your new custom widget
import 'package:klockerapp/screens/employee-screens/components/k_text_input_field.dart';

class AddEmployee extends StatefulWidget {
  const AddEmployee({super.key});

  @override
  State<AddEmployee> createState() => _AddEmployeeState();
}

class _AddEmployeeState extends State<AddEmployee> {
  // Use a GlobalKey to manage the Form state
  final _formKey = GlobalKey<FormState>();

  // Create controllers to get the values from the text fields
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  // ... create controllers for all other fields

  @override
  void dispose() {
    // Dispose controllers to free up resources
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use a Form widget and the key to enable validation
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Use all-around padding
        child: SingleChildScrollView(
          // Prevents overflow on small screens
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Personal Details",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),

              // Your new modular text fields!
              KTextInputField(
                controller: nameController,
                labelText: "Name",
                hintText: "Enter Employee Name",
                icon: Icons.person,
              ),
              KTextInputField(
                controller: emailController,
                labelText: "Email",
                hintText: "Enter Employee Email",
                icon: Icons.email,
              ),
              KTextInputField(
                controller: phoneController,
                labelText: "Phone Number",
                hintText: "Enter Employee Phone Number",
                icon: Icons.phone,
              ),
              const KTextInputField(
                labelText: "Address",
                hintText: "Enter Employee Address",
                icon: Icons.location_on,
              ),
              const KTextInputField(
                labelText: "Password",
                hintText: "Enter Employee Password",
                icon: Icons.lock,
                isPassword: true, // This field will hide the text
              ),
              const KTextInputField(
                labelText: "Confirm Password",
                hintText: "Confirm Your Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 24),
              // You can add more sections here...
            ],
          ),
        ),
      ),
    );
  }
}
