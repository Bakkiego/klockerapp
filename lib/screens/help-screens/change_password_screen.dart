import 'package:flutter/material.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';

/// Change password. Serves both flows:
///
///  * `isForced: true`  — first login with an admin-issued password. No way
///    back; the user must set their own before reaching the app.
///  * `isForced: false` — voluntary change from settings. Dismissable.
///
/// Pops with `true` once the password has been changed.
class ChangePasswordScreen extends StatefulWidget {
  final bool isForced;

  const ChangePasswordScreen({super.key, this.isForced = false});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const _accent = Color(0xFF00A36C);

  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await SupabaseService().changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Password changed'),
          backgroundColor: _accent,
        ),
      );

      navigator.pop(true);
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      // Forced flow: no back gesture, no back button.
      canPop: !widget.isForced,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.isForced,
          centerTitle: true,
          title: Text(
            widget.isForced ? 'Set your password' : 'Change password',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (widget.isForced) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _accent.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_outline, color: _accent),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your account is still using the password your '
                              'administrator set up. Choose your own to continue.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  TextFormField(
                    controller: _currentController,
                    obscureText: !_showCurrent,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: widget.isForced
                          ? 'Password from your administrator'
                          : 'Current password',
                      prefixIcon: const Icon(Icons.key_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showCurrent
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _showCurrent = !_showCurrent),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Enter your current password'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _newController,
                    obscureText: !_showNew,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'New password',
                      helperText: 'At least 8 characters',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(() => _showNew = !_showNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Choose a new password';
                      }
                      if (v.length < 8) {
                        return 'Use at least 8 characters';
                      }
                      if (v == _currentController.text) {
                        return 'This is your current password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmController,
                    obscureText: !_showNew,
                    decoration: InputDecoration(
                      labelText: 'Confirm new password',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v != _newController.text
                        ? 'Both new password fields must match'
                        : null,
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.isForced
                                  ? 'Set password and continue'
                                  : 'Change password',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  if (widget.isForced) ...[
                    const SizedBox(height: 16),
                    Text(
                      'You will use this password every time you sign in. '
                      'Your administrator cannot see it.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
