import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart'; // 🚀 Added for PDFs/Docs
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:klockerapp/providers/user_provider.dart';
import 'package:intl/intl.dart';

import 'help-screens/change_password_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Personal Info ---
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedGender;

  // --- Emergency Contact ---
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  // --- Professional Background ---
  final _educationController = TextEditingController();
  final _skillsController = TextEditingController();
  final _expertiseController = TextEditingController();

  // --- Files & Images ---
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

  // 🚀 Document Picker Logic
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
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00A36C)),
          ),
          child: child!,
        );
      },
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
      if (user == null) throw Exception("Not logged in");

      String? updatedAvatarUrl = _avatarUrl;
      String? updatedCvUrl = _cvUrl;
      String? updatedCertificateUrl = _certificateUrl;

      // 1. Upload Avatar
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
        if (mounted)
          context.read<UserProvider>().setAvatarUrl(updatedAvatarUrl);
      }

      // 2. Upload CV to new Bucket
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

      // 3. Upload Certificate to new Bucket
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

      // 4. Update Database
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00A36C)),
        ),
      );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- AVATAR SECTION ---
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF00A36C).withOpacity(0.5),
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
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickAvatar,
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Color(0xFF00A36C),
                      ),
                      label: const Text(
                        "Update Photo",
                        style: TextStyle(color: Color(0xFF00A36C)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- 1. PERSONAL INFORMATION CARD ---
              _buildSectionHeader(Icons.person_outline, "Personal Information"),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
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
                          border: OutlineInputBorder(),
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
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: "Male",
                                  child: Text("Male"),
                                ),
                                DropdownMenuItem(
                                  value: "Female",
                                  child: Text("Female"),
                                ),
                                DropdownMenuItem(
                                  value: "Other",
                                  child: Text("Other"),
                                ),
                                DropdownMenuItem(
                                  value: "Prefer not to say",
                                  child: Text("Unspecified"),
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

              // --- 2. EMERGENCY CONTACT CARD ---
              _buildSectionHeader(
                Icons.local_hospital_outlined,
                "Emergency Contact",
              ),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emergencyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Name',
                          prefixIcon: Icon(Icons.health_and_safety_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emergencyPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Contact Phone',
                          prefixIcon: Icon(Icons.phone_in_talk_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 3. PROFESSIONAL BACKGROUND CARD ---
              _buildSectionHeader(
                Icons.work_outline,
                "Professional Background",
              ),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _educationController,
                        decoration: const InputDecoration(
                          labelText: 'Education',
                          prefixIcon: Icon(Icons.school_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _skillsController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Core Skills',
                          prefixIcon: Icon(Icons.star_border_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _expertiseController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Expertise & Prior Experience',
                          prefixIcon: Icon(Icons.work_history_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 🚀 --- 4. DIGITAL DOCUMENTS VAULT ---
              _buildSectionHeader(
                Icons.folder_shared_outlined,
                "Digital Documents",
              ),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildFileUploader(
                        title: "Resume / CV",
                        hasExistingFile: _cvUrl != null,
                        pendingFileName: _cvFileName,
                        onTap: () => _pickDocument(true),
                      ),
                      const Divider(height: 32),
                      _buildFileUploader(
                        title: "Educational Certificate",
                        hasExistingFile: _certificateUrl != null,
                        pendingFileName: _certificateFileName,
                        onTap: () => _pickDocument(false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // --- SAVE BUTTON ---
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAll,
                icon: const Icon(Icons.save),
                label: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Save Profile",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF00A36C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildAccountSection(context), // 🚀 add this
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 Reusable UI for the Document Upload Buttons
  Widget _buildFileUploader({
    required String title,
    required bool hasExistingFile,
    required String? pendingFileName,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Icon(
          hasExistingFile || pendingFileName != null
              ? Icons.check_circle
              : Icons.upload_file,
          color: hasExistingFile || pendingFileName != null
              ? Colors.green
              : Colors.grey,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (pendingFileName != null)
                Text(
                  "Ready to save: $pendingFileName",
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                )
              else if (hasExistingFile)
                const Text(
                  "Document attached",
                  style: TextStyle(fontSize: 12, color: Colors.green),
                )
              else
                const Text(
                  "No file attached",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF00A36C),
            side: const BorderSide(color: Color(0xFF00A36C)),
          ),
          child: const Text("Upload"),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ACCOUNT",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00A36C).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Color(0xFF00A36C),
                size: 20,
              ),
            ),
            title: const Text("Change password"),
            subtitle: const Text(
              "Update the password you sign in with",
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
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
