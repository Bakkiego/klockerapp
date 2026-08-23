import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../supabase/repo/supabase_service.dart';
import 'change_password_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _startTimeStr;
  String? _endTimeStr;
  String? _logoUrl;
  File? _localImageFile;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final data = await SupabaseService().getTenantSettings();
      if (data != null && mounted) {
        setState(() {
          _nameController.text = data['company_name'] ?? '';
          _countryController.text = data['country'] ?? '';
          _phoneController.text = data['company_phone'] ?? '';
          _startTimeStr = data['start_time'];
          _endTimeStr = data['end_time'];
          _logoUrl = data['logo_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _localImageFile = File(image.path);
      });
    }
  }

  Future<void> _selectTime(
    BuildContext context, {
    required bool isStartTime,
  }) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTimeStr = picked.format(context);
        } else {
          _endTimeStr = picked.format(context);
        }
      });
    }
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      String? updatedLogoUrl = _logoUrl;

      // Upload image if a new one was selected
      if (_localImageFile != null) {
        updatedLogoUrl = await SupabaseService().uploadCompanyLogo(
          _localImageFile!,
        );
      }

      // Grab current system choices safely from background storage state if needed
      final currentSettings = await SupabaseService().getTenantSettings();

      await SupabaseService().updateTenantSettings(
        name: _nameController.text.trim(),
        country: _countryController.text.trim(),
        phone: _phoneController.text.trim(),
        startTime: _startTimeStr ?? '09:00 AM',
        endTime: _endTimeStr ?? '05:00 PM',
        currency: currentSettings?['currency'] ?? 'ZAR',
        language: currentSettings?['language'] ?? 'English',
        logoUrl: updatedLogoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00A36C)),
      );

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickLogo,
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF00A36C).withOpacity(0.5),
                            width: 2,
                          ),
                          image: _localImageFile != null
                              ? DecorationImage(
                                  image: FileImage(_localImageFile!),
                                  fit: BoxFit.cover,
                                )
                              : (_logoUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_logoUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null),
                        ),
                        child: _localImageFile == null && _logoUrl == null
                            ? const Icon(
                                Icons.storefront,
                                size: 50,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickLogo,
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Color(0xFF00A36C),
                      ),
                      label: const Text(
                        "Change Logo",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF00A36C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Company Name',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Country',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Telephone Number',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, isStartTime: true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Time',
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00A36C)),
                          ),
                        ),
                        child: Text(_startTimeStr ?? 'Set Operational Start'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, isStartTime: false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Time',
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00A36C)),
                          ),
                        ),
                        child: Text(_endTimeStr ?? 'Set Operational End'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A36C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _saveAll,
                child: Text(
                  _isSaving ? "Saving..." : "Save Changes",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
