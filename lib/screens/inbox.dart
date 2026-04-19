import 'package:flutter/material.dart';
import 'chat_screen.dart';

class Inbox extends StatelessWidget {
  const Inbox({super.key});

  final List<Map<String, String>> _mockConversations = const [
    {
      'name': 'Raza',
      'lastMessage': 'I sent the file yesterday. Check your drive.',
      'time': '10:30 AM',
      'unreadCount': '2',
      'avatarColor': '0xFF4CAF50',
    },
    {
      'name': 'Jessica (HR)',
      'lastMessage': 'Your salary rate has been updated.',
      'time': '9:15 AM',
      'unreadCount': '0',
      'avatarColor': '0xFF2196F3',
    },
    {
      'name': 'System Alerts',
      'lastMessage': 'Payroll run initiated successfully.',
      'time': 'Dec 10',
      'unreadCount': '1',
      'avatarColor': '0xFFFF9800',
    },
    {
      'name': 'Milo (Finance)',
      'lastMessage': 'Meeting moved to 2 PM.',
      'time': 'Dec 09',
      'unreadCount': '0',
      'avatarColor': '0xFF9C27B0',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Get colors that are automatically theme-aware
    final Color readMessageColor = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant;
    final Color unreadMessageColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Implement settings or filter
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _mockConversations.length,
        itemBuilder: (context, index) {
          final conversation = _mockConversations[index];
          final unreadCount = int.tryParse(conversation['unreadCount']!) ?? 0;
          final avatarColor = Color(int.parse(conversation['avatarColor']!));

          // Determine the styling based on unread count
          final bool isUnread = unreadCount > 0;
          final Color subtitleColor = isUnread
              ? unreadMessageColor
              : readMessageColor.withOpacity(
                  0.7,
                ); // Apply a slight opacity to the 'read' color
          final Color timeColor = isUnread
              ? Colors.green.shade700
              : readMessageColor.withOpacity(0.5);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            child: Card(
              elevation: 0,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: avatarColor,
                  child: Text(
                    conversation['name']![0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  conversation['name']!,
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  conversation['lastMessage']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    // Use theme-aware color logic for readability in dark mode
                    color: subtitleColor,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      conversation['time']!,
                      style: TextStyle(
                        fontSize: 12,
                        // Use theme-aware color for time stamp
                        color: timeColor,
                        fontWeight: isUnread
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (isUnread)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.green,
                          child: Text(
                            conversation['unreadCount']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatScreen(recipientName: conversation['name']!),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
