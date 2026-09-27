import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:klockerapp/providers/user_provider.dart';
import 'package:klockerapp/utils/custom_theme/k_palette.dart';
import 'package:intl/intl.dart';

import 'help-screens/change_password_screen.dart';

/// Reference conversion — no colour literals remain in this file.
///
/// Patterns used here apply to every other screen:
///   * Card( ... ) with no shape — the card theme supplies border + radius
///   * ElevatedButton with no style — the button theme supplies it
///   * green as a FILL      -> scheme.primary
///   * green as TEXT/ICON   -> context.brandText
///   * Colors.grey (labels) -> scheme.onSurfaceVariant
///   * success / info state -> context.status.*
///   * showDatePicker builder override -> deleted, datePickerTheme handles it
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedGender;

  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  final _educationController = TextEditingController();
  final _skillsController = TextEditingController();
  final _expertiseController = TextEditingController();

  String? _avatarUrl;
  File? _localImageFile;

  String? _cvUrl;
  File? _localCvFile;
  String? _cvFileName;

  String? _certificateUrl;
  File? _localCertificateFile;
  String? _certificateFileName;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _educationController.dispose();
    _skillsController.dispose();
    _expertiseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _nameController.text = data['full_name'] ?? '';
          _phoneController.text = data['phone_number'] ?? '';
          _addressController.text = data['address'] ?? '';
          _dobController.text = data['date_of_birth'] ?? '';
          _selectedGender = data['gender'];

          _emergencyNameController.text = data['emergency_contact_name'] ?? '';
          _emergencyPhoneController.text =
              data['emergency_contact_phone'] ?? '';

          _educationController.text = data['education'] ?? '';
          _skillsController.text = data['skills'] ?? '';
          _expertiseController.text = data['expertise'] ?? '';

          _avatarUrl = data['avatar_url'];
          _cvUrl = data['cv_url'];
          _certificateUrl = data['certificate_url'];

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _localImageFile = File(image.path));
    }
  }

  Future<void> _pickDocument(bool isCv) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        if (isCv) {
          _localCvFile = File(result.files.single.path!);
          _cvFileName = result.files.single.name;
        } else {
          _localCertificateFile = File(result.files.single.path!);
          _certificateFileName = result.files.single.name;
        }
      });
    }
  }

  Future<void> _pickDateOfBirth() async {
    // The builder override is gone. It forced ColorScheme.light, which
    // rendered the calendar black-on-black in dark mode. datePickerTheme
    // now handles both.
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(
        () => _dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate),
      );
    }
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      String? updatedAvatarUrl = _avatarUrl;
      String? updatedCvUrl = _cvUrl;
      String? updatedCertificateUrl = _certificateUrl;

      if (_localImageFile != null) {
        final ext = _localImageFile!.path.split('.').last;
        final name =
            'avatar-${user.id}-${DateTime.now().millisecondsSinceEpoch}.$ext';
        await client.storage
            .from('avatars')
            .upload(
              name,
              _localImageFile!,
              fileOptions: const FileOptions(upsert: true),
            );
        updatedAvatarUrl = client.storage.from('avatars').getPublicUrl(name);
        if (mounted) {
          context.read<UserProvider>().setAvatarUrl(updatedAvatarUrl);
        }
      }

      if (_localCvFile != null) {
        final ext = _localCvFile!.path.split('.').last;
        final name =
            'cv-${user.id}-${DateTime.now().millisecondsSinceEpoch}.$ext';
        await client.storage
            .from('employee_documents')
            .upload(
              name,
              _localCvFile!,
              fileOptions: const FileOptions(upsert: true),
            );
        updatedCvUrl = client.storage
            .from('employee_documents')
            .getPublicUrl(name);
      }

      if (_localCertificateFile != null) {
        final ext = _localCertificateFile!.path.split('.').last;
        final name =
            'cert-${user.id}-${DateTime.now().millisecondsSinceEpoch}.$ext';
        await client.storage
            .from('employee_documents')
            .upload(
              name,
              _localCertificateFile!,
              fileOptions: const FileOptions(upsert: true),
            );
        updatedCertificateUrl = client.storage
            .from('employee_documents')
            .getPublicUrl(name);
      }

      await client
          .from('profiles')
          .update({
            'full_name': _nameController.text.trim(),
            'phone_number': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
            'date_of_birth': _dobController.text.trim(),
            'gender': _selectedGender,
            'emergency_contact_name': _emergencyNameController.text.trim(),
            'emergency_contact_phone': _emergencyPhoneController.text.trim(),
            'education': _educationController.text.trim(),
            'skills': _skillsController.text.trim(),
            'expertise': _expertiseController.text.trim(),
            'avatar_url': updatedAvatarUrl,
            'cv_url': updatedCvUrl,
            'certificate_url': updatedCertificateUrl,
          })
          .eq('id', user.id);

      if (mounted) {
        context.read<UserProvider>().setFullName(_nameController.text.trim());
        // The snackbar theme supplies the colours now.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_isLoading) {
      // No colour argument — progressIndicatorTheme supplies it.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- AVATAR ---
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickAvatar,
                          child: Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainer,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.primary.withOpacity(0.5),
                                width: 3,
                              ),
                              image: _localImageFile != null
                                  ? DecorationImage(
                                      image: FileImage(_localImageFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : (_avatarUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(_avatarUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null),
                            ),
                            child: _localImageFile == null && _avatarUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: scheme.onSurfaceVariant,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // textButtonTheme already supplies brandText as the
                        // foreground, so no style needed.
                        TextButton.icon(
                          onPressed: _pickAvatar,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Update Photo'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- PERSONAL ---
                  _sectionHeader(Icons.person_outline, 'Personal Information'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Home Address',
                              prefixIcon: Icon(Icons.home_outlined),
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _dobController,
                                  readOnly: true,
                                  onTap: _pickDateOfBirth,
                                  decoration: const InputDecoration(
                                    labelText: 'Date of Birth',
                                    prefixIcon: Icon(Icons.cake_outlined),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedGender,
                                  decoration: const InputDecoration(
                                    labelText: 'Gender',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Male',
                                      child: Text('Male'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Female',
                                      child: Text('Female'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Other',
                                      child: Text('Other'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Prefer not to say',
                                      child: Text('Unspecified'),
                                    ),
                                  ],
                                  onChanged: (val) =>
                                      setState(() => _selectedGender = val),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- EMERGENCY ---
                  _sectionHeader(
                    Icons.local_hospital_outlined,
                    'Emergency Contact',
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emergencyNameController,
                            decoration: const InputDecoration(
                              labelText: 'Contact Name',
                              prefixIcon: Icon(
                                Icons.health_and_safety_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emergencyPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Contact Phone',
                              prefixIcon: Icon(Icons.phone_in_talk_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- PROFESSIONAL ---
                  _sectionHeader(Icons.work_outline, 'Professional Background'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _educationController,
                            decoration: const InputDecoration(
                              labelText: 'Education',
                              prefixIcon: Icon(Icons.school_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _skillsController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Core Skills',
                              prefixIcon: Icon(Icons.star_border_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _expertiseController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Expertise & Prior Experience',
                              prefixIcon: Icon(Icons.work_history_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- DOCUMENTS ---
                  _sectionHeader(
                    Icons.folder_shared_outlined,
                    'Digital Documents',
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _fileUploader(
                            title: 'Resume / CV',
                            hasExistingFile: _cvUrl != null,
                            pendingFileName: _cvFileName,
                            onTap: () => _pickDocument(true),
                          ),
                          const Divider(height: 32),
                          _fileUploader(
                            title: 'Educational Certificate',
                            hasExistingFile: _certificateUrl != null,
                            pendingFileName: _certificateFileName,
                            onTap: () => _pickDocument(false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // The elevatedButtonTheme supplies colour, padding, radius
                  // and text style, so the local style block is gone.
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveAll,
                    icon: _isSaving
                        ? const SizedBox.shrink()
                        : const Icon(Icons.save),
                    label: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimary,
                            ),
                          )
                        : const Text('Save Profile'),
                  ),

                  const SizedBox(height: 32),
                  _accountSection(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _fileUploader({
    required String title,
    required bool hasExistingFile,
    required String? pendingFileName,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasFile = hasExistingFile || pendingFileName != null;

    // "Ready to save" and "Document attached" are states, so they use the
    // status tokens rather than Colors.blue / Colors.green.
    final (subColour, subText) = pendingFileName != null
        ? (context.status.overtimeFg, 'Ready to save: $pendingFileName')
        : hasExistingFile
        ? (context.status.approvedFg, 'Document attached')
        : (scheme.onSurfaceVariant, 'No file attached');

    return Row(
      children: [
        Icon(
          hasFile ? Icons.check_circle : Icons.upload_file,
          color: hasFile ? context.status.approvedFg : scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              Text(
                subText,
                style: theme.textTheme.bodySmall?.copyWith(color: subColour),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        OutlinedButton(onPressed: onTap, child: const Text('Upload')),
      ],
    );
  }

  Widget _accountSection(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACCOUNT',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                color: scheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            title: const Text('Change password'),
            subtitle: const Text('Update the password you sign in with'),
            trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
            ),
          ),
        ),
      ],
    );
  }
}
