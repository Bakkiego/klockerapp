import 'package:flutter/material.dart';
import '../supabase/repo/supabase_service.dart';

class EmployeeWelcomeScreen extends StatefulWidget {
  static String id = 'welcome_screen';
  late final String tenantId;
  late final String companyName;

  EmployeeWelcomeScreen({
    super.key,
    required this.tenantId,
    required this.companyName,
  });

  @override
  State<EmployeeWelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<EmployeeWelcomeScreen> {
  final SupabaseService _service = SupabaseService();
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _completeSignUp() async {
    // Basic validation
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in required fields")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _service.signUpEmployee(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        tenantId:
            widget.tenantId, // Using the ID we passed from the previous screen!
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account Created!"),
            backgroundColor: Color(0xFF00A36C),
          ),
        );
        // Navigate them back to the login screen to sign in, OR push them straight to the BottomNav
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome to",
              style: TextStyle(fontSize: 24, color: Colors.grey),
            ),
            Text(
              widget.companyName, // Custom welcome!
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A36C),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Let's set up your employee profile.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),

            // Form Fields
            TextField(
              controller: _nameController,
              style: TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: "Full Name",
                labelStyle: TextStyle(color: Colors.black),
                floatingLabelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              style: TextStyle(color: Colors.black),
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                labelStyle: TextStyle(color: Colors.black),
                floatingLabelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              style: TextStyle(color: Colors.black),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Work Email",
                labelStyle: TextStyle(color: Colors.black),
                floatingLabelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              style: TextStyle(color: Colors.black),
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Create Password",
                labelStyle: TextStyle(color: Colors.black),
                floatingLabelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),

            // Submit Button
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A36C)),
                  )
                : ElevatedButton(
                    onPressed: _completeSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A36C),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      "Complete Setup",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
