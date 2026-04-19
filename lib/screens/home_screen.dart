import 'package:flutter/material.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/attendance_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  static String id = 'home_screen';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final data = await _supabase
            .from('profiles')
            .select('*, tenants(name)')
            .eq('id', user.id)
            .single();

        setState(() {
          userProfile = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // We use a Container instead of a Scaffold to live inside the BottomNav's Scaffold
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        // We only want to push down from the top, the BottomNav handles the bottom
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // --- HEADER SECTION ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    // 1. Logo
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Image.asset(
                        'images/logo.png',
                        errorBuilder: (context, error, stack) => Icon(
                          Icons.business,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 2. Welcome Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello, ${userProfile?['full_name'] ?? 'User'}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            userProfile?['tenants']?['name'] ?? 'No Tenant',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 3. Profile Image
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.primary.withOpacity(
                        0.1,
                      ),
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // --- SEARCH BAR ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SearchBar(
                  elevation: WidgetStateProperty.all(0),
                  backgroundColor: WidgetStateProperty.all(
                    isDark ? Colors.grey[900] : Colors.grey[200],
                  ),
                  hintText: 'Type Feature',
                  trailing: const [Icon(Icons.search_sharp)],
                ),
              ),

              const SizedBox(height: 20),
              const AttendanceSummary(),
              const Divider(indent: 20, endIndent: 20),

              // --- CALENDAR ---
              // Wrapped in a SizedBox so it doesn't try to take up infinite height
              SizedBox(
                height: 400,
                child: CalendarDatePicker(
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                  onDateChanged: (DateTime pickedDate) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
