import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../supabase/repo/supabase_service.dart';
import 'package:klockerapp/providers/user_provider.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:provider/provider.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  bool _isFetchingLocation = false;
  bool _isLoadingData = true;

  String? _selectedTimezone;
  String? _selectedCurrency;
  String? _selectedLanguage;
  Map<String, dynamic>? _tenantData;

  @override
  void initState() {
    super.initState();
    _loadSystemConfig();
  }

  Future<void> _loadSystemConfig() async {
    try {
      final data = await SupabaseService().getTenantSettings();
      if (data != null && mounted) {
        setState(() {
          _tenantData = data;
          _selectedTimezone = data['timezone'] ?? 'SAST';
          _selectedCurrency = data['currency'] ?? 'ZAR';
          _selectedLanguage = data['language'] ?? 'English';
          _isLoadingData = false;
        });

        // 🚀 THE FIX: Push the loaded currency to the provider immediately
        if (_selectedCurrency != null) {
          final loadedCurrency = CurrencyService().findByCode(
            _selectedCurrency!,
          );
          if (loadedCurrency != null) {
            context.read<UserProvider>().setCurrencySymbol(
              loadedCurrency.symbol,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _updateSystemConfig(String type, String value) async {
    if (_tenantData == null) return;

    // Smooth local updates immediately
    setState(() {
      if (type == 'tz') _selectedTimezone = value;
      if (type == 'curr') _selectedCurrency = value;
      if (type == 'lang') _selectedLanguage = value;
    });

    try {
      await SupabaseService().updateTenantSettings(
        name: _tenantData!['company_name'] ?? '',
        country: _tenantData!['country'] ?? '',
        phone: _tenantData!['company_phone'] ?? '',
        startTime: _tenantData!['start_time'] ?? '09:00 AM',
        endTime: _tenantData!['end_time'] ?? '05:00 PM',
        timezone: _selectedTimezone ?? 'SAST',
        currency: _selectedCurrency ?? 'ZAR',
        language: _selectedLanguage ?? 'English',
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        throw Exception('Permissions denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissions permanently denied.');
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _setupBranchLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      Position position = await _determinePosition();
      String foundAddress = "Unknown Street Address";

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          foundAddress = '${place.street}, ${place.locality}, ${place.country}'
              .replaceAll(RegExp(r'^, |, $'), '')
              .trim();
        }
      } catch (e) {
        foundAddress =
            "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
      }

      final branches = await SupabaseService().getAdminBranches();
      if (branches.isEmpty)
        throw Exception("No branches found. Please create a branch first!");

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Set Branch Geofence"),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A36C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00A36C).withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Location Found:",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          foundAddress,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00A36C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Assign this location to a branch:"),
                  const SizedBox(height: 10),
                  ...branches.map(
                    (branch) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        branch['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(
                        Icons.pin_drop,
                        color: Color(0xFF00A36C),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        try {
                          await SupabaseService().updateBranchLocation(
                            branchId: branch['id'],
                            lat: position.latitude,
                            lng: position.longitude,
                            radiusMeters: 100,
                            newAddress: foundAddress,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Branch updated!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("Error: $e")));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData)
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00A36C)),
      );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Branch Geofence Setup",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _isFetchingLocation ? null : _setupBranchLocation,
              icon: _isFetchingLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: Color(0xFF00A36C)),
              label: Text(
                _isFetchingLocation
                    ? "Finding Location..."
                    : "Locate & Lock GPS",
                style: const TextStyle(fontSize: 18, color: Color(0xFF00A36C)),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _selectedTimezone,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Company Core TimeZone',
            ),
            items: const [
              DropdownMenuItem(
                value: "SAST",
                child: Text("Johannesburg (SAST)"),
              ),
              DropdownMenuItem(value: "UK", child: Text("London (GMT)")),
              DropdownMenuItem(value: "Pacific", child: Text("Pacific (PST)")),
            ],
            onChanged: (val) => _updateSystemConfig('tz', val!),
          ),
          const SizedBox(height: 16),

          // --- THE NEW CURRENCY PICKER ---
          const Text(
            "System Currency",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              showCurrencyPicker(
                context: context,
                showFlag: true,
                showCurrencyName: true,
                showCurrencyCode: true,
                favorite: [
                  'ZAR',
                  'USD',
                  'EUR',
                  'GBP',
                ], // Puts these at the top of the list!
                onSelect: (Currency currency) {
                  // 1. Update Local UI
                  setState(() => _selectedCurrency = currency.code);

                  // 2. Update Provider (Changes it everywhere in the app instantly!)
                  context.read<UserProvider>().setCurrencySymbol(
                    currency.symbol,
                  );

                  // 3. Save to Supabase Database
                  _updateSystemConfig('curr', currency.code);
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCurrency ?? "Select Currency",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _selectedLanguage,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'System Language',
            ),
            items: const [
              DropdownMenuItem(value: "English", child: Text("English")),
              DropdownMenuItem(value: "French", child: Text("Français")),
              DropdownMenuItem(value: "Mandarin", child: Text("中文")),
            ],
            onChanged: (val) => _updateSystemConfig('lang', val!),
          ),
        ],
      ),
    );
  }
}
