import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// 🚀 Make sure this path points to your GoogleCalendarService!
import 'package:klockerapp/supabase/google_calendar_service.dart';

import '../zoom_meetings_screen.dart';

class SocialSettingsScreen extends StatefulWidget {
  const SocialSettingsScreen({super.key});

  @override
  State<SocialSettingsScreen> createState() => _SocialSettingsScreenState();
}

class _SocialSettingsScreenState extends State<SocialSettingsScreen> {
  // 🚀 Initialize the real Google Service
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  bool _isGoogleConnected = false;
  bool _isZoomConnected = false; // Zoom is still a mockup for now
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkConnections();
  }

  // 🚀 Check if they are already signed in when the screen opens
  Future<void> _checkConnections() async {
    try {
      // 1. Ask the service to check the browser cookies silently
      bool wasAlreadyConnected = await _calendarService.restoreSession();

      // 2. Update the UI based on what it found
      if (mounted) {
        setState(() {
          _isGoogleConnected = wasAlreadyConnected;
          _isLoading = false; // Turn off the loading spinner
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGoogleConnected = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Integrations",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Connected Accounts",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Sync your external accounts to unlock powerful scheduling and calendar features.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // ==========================================
                  // --- GOOGLE WORKSPACE CARD (WIRED UP) ---
                  // ==========================================
                  _buildIntegrationCard(
                    title: "Google Workspace",
                    subtitle: "Sync Google Calendar & Meet",
                    icon: FontAwesomeIcons.google,
                    iconColor: Colors.redAccent,
                    isConnected: _isGoogleConnected,
                    isDark: isDark,
                    onToggle: () async {
                      if (_isGoogleConnected) {
                        // 🚀 DISCONNECT IF ALREADY CONNECTED
                        await _calendarService.disconnect();
                        setState(() => _isGoogleConnected = false);
                      } else {
                        // 🚀 TRIGGER REAL GOOGLE SIGN-IN IF NOT CONNECTED
                        final account = await _calendarService
                            .connectCalendar();
                        if (account != null) {
                          setState(() => _isGoogleConnected = true);
                        }
                      }
                    },
                  ),

                  const SizedBox(height: 16),
                  // ==========================================
                  // --- ZOOM CARD (Smart Calendar Sync) ---
                  // ==========================================
                  _buildIntegrationCard(
                    title: "Zoom",
                    subtitle: "View your synced Zoom meetings",
                    icon: FontAwesomeIcons.video,
                    iconColor: Colors.blueAccent,
                    isConnected:
                        _isGoogleConnected, // Relies on Google Calendar connection!
                    isDark: isDark,
                    onToggle: () {
                      if (!_isGoogleConnected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Please connect Google Workspace first to sync Zoom meetings.",
                            ),
                          ),
                        );
                        return;
                      }

                      // Navigate to the new Zoom Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ZoomMeetingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  // --- REUSABLE UI BUILDER ---
  // 🚀 UPGRADED: icon parameter changed to FaIconData to handle FontAwesome v11
  Widget _buildIntegrationCard({
    required String title,
    required String subtitle,
    required FaIconData icon,
    required Color iconColor,
    required bool isConnected,
    required bool isDark,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected
              ? Colors.green.withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
          width: isConnected ? 2 : 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isConnected ? Icons.check_circle : Icons.error_outline,
                        color: isConnected ? Colors.green : Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isConnected ? "Connected" : "Not Connected",
                        style: TextStyle(
                          color: isConnected ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onToggle,
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected
                  ? Colors.grey.withOpacity(0.2)
                  : const Color(0xFF00A36C),
              foregroundColor: isConnected
                  ? (isDark ? Colors.white : Colors.black)
                  : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(isConnected ? "Disconnect" : "Connect"),
          ),
        ],
      ),
    );
  }
}
