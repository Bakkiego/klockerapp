import 'package:flutter/material.dart';
import 'package:klockerapp/models/app_enums.dart';
import 'package:klockerapp/screens/employee_welcome_screen.dart';
import '../components/bottom_nav.dart';
import '../supabase/repo/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  static String id = 'login_screen';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isSignUp = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 80),
            Center(
              child: SizedBox(
                width: 120,
                child: Image.asset('images/logo.png'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Welcome to KlockerApp",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Manage your workforce with EASE",
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 40),

            // --- THE PILL TOGGLE ---
            Container(
              width: 300,
              height: 50,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[850]
                    : Colors.grey[300], // This restores the "pill" track look
                borderRadius: BorderRadius.circular(25),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: isSignUp
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 150,
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _toggleTab(
                        "Sign In",
                        !isSignUp,
                        () => setState(() => isSignUp = false),
                      ),
                      _toggleTab(
                        "Sign Up",
                        isSignUp,
                        () => setState(() => isSignUp = true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- THE FORM AREA ---
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surface
                    : Colors.white, // Pure white in Light Mode
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black54
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: isSignUp
                  ? const RoleSelectionWidget()
                  : const SignInForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleTab(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// --- SUB-WIDGET: ROLE SELECTION ---
class RoleSelectionWidget extends StatefulWidget {
  const RoleSelectionWidget({super.key});

  @override
  State<RoleSelectionWidget> createState() => _RoleSelectionWidgetState();
}

class _RoleSelectionWidgetState extends State<RoleSelectionWidget> {
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Get Started as...",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        _roleButton(
          "Administrator",
          Icons.admin_panel_settings_rounded,
          'admin',
        ),
        const SizedBox(height: 16),
        _roleButton("Employee", Icons.badge_rounded, 'employee'),
        if (selectedRole != null) ...[
          const SizedBox(height: 30),
          selectedRole == 'admin'
              ? const AdminSignUpFields()
              : const EmployeeSignUpFields(),
        ],
      ],
    );
  }

  Widget _roleButton(String title, IconData icon, String role) {
    final theme = Theme.of(context);
    bool isSelected = selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : (theme.brightness == Brightness.dark
                    ? Colors.grey[900]
                    : Colors.white),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : theme.colorScheme.primary,
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// --- ADMIN SIGN UP FORM ---
class AdminSignUpFields extends StatefulWidget {
  const AdminSignUpFields({super.key});
  @override
  State<AdminSignUpFields> createState() => _AdminSignUpFieldsState();
}

class _AdminSignUpFieldsState extends State<AdminSignUpFields> {
  final emailCont = TextEditingController();
  final passCont = TextEditingController();
  final phoneCont = TextEditingController();
  final nameCont = TextEditingController();
  final bizCont = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _inputField("Business Name", bizCont),
        const SizedBox(height: 10),
        _inputField("Full Name", nameCont),
        const SizedBox(height: 10),
        _inputField("Phone Number", phoneCont, isNumber: true),
        const SizedBox(height: 10),
        _inputField("Email", emailCont),
        const SizedBox(height: 10),
        _inputField("Password", passCont, isPass: true),
        const SizedBox(height: 30),
        _pillButton("Sign Up", () async {
          try {
            await SupabaseService().signUpAdmin(
              email: emailCont.text.trim(),
              password: passCont.text.trim(),
              fullName: nameCont.text.trim(),
              businessName: bizCont.text.trim(),
              phoneNumber: int.parse(phoneCont.text.trim()),
            );
          } catch (e) {
            print("Sign up error: $e");
          }
        }),
      ],
    );
  }

  Widget _inputField(
    String label,
    TextEditingController cont, {
    bool isPass = false,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: cont,
      obscureText: isPass,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _pillButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: const StadiumBorder(),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

// --- EMPLOYEE SIGN UP FORM ---
class EmployeeSignUpFields extends StatefulWidget {
  const EmployeeSignUpFields({super.key});
  @override
  State<EmployeeSignUpFields> createState() => _EmployeeSignUpFieldsState();
}

class _EmployeeSignUpFieldsState extends State<EmployeeSignUpFields> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: "Enter Company Code",
            prefixIcon: Icon(Icons.business),
          ),
        ),
        const SizedBox(height: 30),
        _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: () async {
                  setState(() => _isLoading = true);
                  final companyData = await SupabaseService().verifyCompanyCode(
                    _codeController.text.trim(),
                  );
                  setState(() => _isLoading = false);
                  if (companyData != null && mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmployeeWelcomeScreen(
                          tenantId: companyData['id'],
                          companyName: companyData['name'],
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  "Verify Code",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
      ],
    );
  }
}

// --- SIGN IN FORM ---
class SignInForm extends StatefulWidget {
  const SignInForm({super.key});
  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final emailCont = TextEditingController();
  final passCont = TextEditingController();
  bool _isLoading = false;

  void _handleSignIn() async {
    if (emailCont.text.isEmpty || passCont.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final userData = await SupabaseService().signInUser(
        emailCont.text.trim(),
        passCont.text.trim(),
      );
      final userRole role = userRole.fromString(userData['role']);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomNav(role: role)),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: emailCont,
          decoration: const InputDecoration(labelText: "Email"),
        ),
        const SizedBox(height: 30),
        TextFormField(
          controller: passCont,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Password"),
        ),
        const SizedBox(height: 40),
        _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _handleSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  "Sign In",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
      ],
    );
  }
}
