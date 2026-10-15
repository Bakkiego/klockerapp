import 'package:flutter/material.dart';
import 'package:klockerapp/utils/custom_theme/k_palette.dart';
import '../supabase/repo/supabase_service.dart';

class EmployeeWelcomeScreen extends StatefulWidget {
  static const String id = 'welcome_screen';

  // These were `late final` with required constructor parameters, which does
  // nothing except stop the widget being const.
  final String tenantId;
  final String companyName;

  const EmployeeWelcomeScreen({
    super.key,
    required this.tenantId,
    required this.companyName,
  });

  @override
  State<EmployeeWelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<EmployeeWelcomeScreen> {
  final SupabaseService _service = SupabaseService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Minimum password length. Supabase's own default floor is 6 — raise or
  /// lower this to match whatever you've set in the dashboard.
  static const _minPasswordLength = 8;

  @override
  void dispose() {
    // None of these were being released.
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: isError
              ? theme.textTheme.bodyMedium?.copyWith(color: scheme.onError)
              : null,
        ),
        backgroundColor: isError ? scheme.error : null,
      ),
    );
  }

  Future<void> _completeSignUp() async {
    // Validation moved onto the fields themselves, so the message appears
    // under the offending box instead of as a single generic snackbar.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final navigator = Navigator.of(context);

    try {
      await _service.signUpEmployee(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        tenantId:
            widget.tenantId, // Using the ID we passed from the previous screen!
      );

      if (!mounted) return;
      _showSnack("Account created. You can sign in now.");
      // Navigate them back to the login screen to sign in
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack("Error: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome to",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    widget.companyName, // Custom welcome!
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: context.brandText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Let's set up your employee profile.",
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 40),

                  // Form Fields
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? "Enter your name" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: "Phone Number (optional)",
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: "Work Email",
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (value) {
                      final email = (value ?? '').trim();
                      if (email.isEmpty) return "Enter your work email";
                      // Deliberately loose — the real check is the
                      // confirmation email landing.
                      final looksLikeEmail = RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(email);
                      return looksLikeEmail
                          ? null
                          : "That doesn't look like an email address";
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!_isLoading) _completeSignUp();
                    },
                    decoration: InputDecoration(
                      labelText: "Create Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      helperText: "At least $_minPasswordLength characters",
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? "Show password"
                            : "Hide password",
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final password = (value ?? '').trim();
                      if (password.isEmpty) return "Choose a password";
                      if (password.length < _minPasswordLength) {
                        return "Use at least $_minPasswordLength characters";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _completeSignUp,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      shape: const StadiumBorder(),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimary,
                            ),
                          )
                        : const Text("Complete Setup"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
