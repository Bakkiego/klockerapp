import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../supabase/repo/supabase_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final data = await SupabaseService().getMyNotifications();
    setState(() {
      _notifications = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : _notifications.isEmpty
          ? const Center(child: Text("You're all caught up!"))
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                final isRead = notif['is_read'] == true;
                final time = DateTime.parse(notif['created_at']);

                return ListTile(
                  tileColor: isRead
                      ? Colors.transparent
                      : const Color(0xFF00A36C).withOpacity(0.05),
                  leading: CircleAvatar(
                    backgroundColor: isRead
                        ? Colors.grey[200]
                        : const Color(0xFF00A36C).withOpacity(0.2),
                    child: Icon(
                      Icons.notifications,
                      color: isRead ? Colors.grey : const Color(0xFF00A36C),
                    ),
                  ),
                  title: Text(
                    notif['title'],
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notif['message']),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(time),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    if (!isRead) {
                      await SupabaseService().markNotificationAsRead(
                        notif['id'],
                      );
                      _loadNotifications(); // Refresh list
                    }
                  },
                );
              },
            ),
    );
  }
}
