import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'inbox.dart'; // Target chat timeline view

class InboxList extends StatefulWidget {
  const InboxList({super.key});

  @override
  State<InboxList> createState() => _InboxListState();
}

class _InboxListState extends State<InboxList> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    final liveData = await SupabaseService().getConversations();
    if (mounted) {
      setState(() {
        _conversations = liveData;
        _isLoading = false;
      });
    }
  }

  // 🚀 BULLETPROOF NEW CHAT MAKER
  void _showNewChatSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: SupabaseService().getEmployees(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A36C)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No team members found."));
                }

                final currentUserId =
                    Supabase.instance.client.auth.currentUser?.id;
                final team = snapshot.data!
                    .where((emp) => emp['id'] != currentUserId)
                    .toList();

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "New Conversation",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: team.length,
                        itemBuilder: (context, index) {
                          final employee = team[index];
                          final String? avatarUrl = employee['avatar_url'];

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xFF00A36C,
                              ).withOpacity(0.1),
                              backgroundImage: avatarUrl != null
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl == null
                                  ? Text(
                                      employee['full_name']?[0].toUpperCase() ??
                                          'U',
                                      style: const TextStyle(
                                        color: Color(0xFF00A36C),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              employee['full_name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              employee['job_title'] ??
                                  employee['role'] ??
                                  'Staff',
                            ),
                            onTap: () async {
                              Navigator.pop(context); // Close bottom sheet

                              // Show spinner loader
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF00A36C),
                                  ),
                                ),
                              );

                              try {
                                // 1. Grab all rooms where current user is participating
                                final roomsResponse = await Supabase
                                    .instance
                                    .client
                                    .from('chat_rooms')
                                    .select('id, user_one, user_two')
                                    .or(
                                      'user_one.eq.$currentUserId,user_two.eq.$currentUserId',
                                    );

                                String? existingRoomId;

                                // 2. Check locally if a room exists with the selected employee
                                for (var room in roomsResponse) {
                                  if (room['user_one'] == employee['id'] ||
                                      room['user_two'] == employee['id']) {
                                    existingRoomId = room['id'];
                                    break;
                                  }
                                }

                                String finalRoomId;

                                // 3. If room doesn't exist, create it safely
                                if (existingRoomId != null) {
                                  finalRoomId = existingRoomId;
                                } else {
                                  final newRoom = await Supabase.instance.client
                                      .from('chat_rooms')
                                      .insert({
                                        'user_one': currentUserId,
                                        'user_two': employee['id'],
                                        'tenant_id':
                                            employee['tenant_id'], // Safely assigns matching workspace context
                                      })
                                      .select('id')
                                      .single();
                                  finalRoomId = newRoom['id'];
                                }

                                if (context.mounted) {
                                  Navigator.pop(
                                    context,
                                  ); // Dismiss loading spinner safely!

                                  // Navigate straight into the chat view
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Inbox(
                                        roomId: finalRoomId,
                                        recipientName:
                                            employee['full_name'] ??
                                            'Co-worker',
                                      ),
                                    ),
                                  );
                                  _loadInbox(); // Refresh main history loop when backing out
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.pop(
                                    context,
                                  ); // Dismiss spinner on fail
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error launching chat: $e"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inbox',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : RefreshIndicator(
              color: const Color(0xFF00A36C),
              onRefresh: _loadInbox,
              child: _conversations.isEmpty
                  ? const Center(
                      child: Text(
                        "No conversations yet. Tap + to start one!",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final conv = _conversations[index];
                        final int unreadCount = conv['unreadCount'];
                        final bool isUnread = unreadCount > 0;
                        final String? avatarUrl = conv['avatar_url'];

                        String timeDisplay = '';
                        if (conv['time'] != null) {
                          final DateTime msgTime = conv['time'];
                          final now = DateTime.now();
                          if (msgTime.day == now.day &&
                              msgTime.month == now.month &&
                              msgTime.year == now.year) {
                            timeDisplay = DateFormat('h:mm a').format(msgTime);
                          } else {
                            timeDisplay = DateFormat('MMM d').format(msgTime);
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 2.0,
                          ),
                          child: Card(
                            elevation: 0,
                            color: isUnread
                                ? const Color(0xFF00A36C).withOpacity(0.05)
                                : Colors.transparent,
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(
                                  0xFF00A36C,
                                ).withOpacity(0.1),
                                backgroundImage: avatarUrl != null
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl == null
                                    ? Text(
                                        conv['name']![0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFF00A36C),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                conv['name'],
                                style: TextStyle(
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                conv['lastMessage'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isUnread
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : Colors.grey.shade600,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    timeDisplay,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isUnread
                                          ? const Color(0xFF00A36C)
                                          : Colors.grey,
                                    ),
                                  ),
                                  if (isUnread)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: CircleAvatar(
                                        radius: 9,
                                        backgroundColor: const Color(
                                          0xFF00A36C,
                                        ),
                                        child: Text(
                                          unreadCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () async {
                                await SupabaseService().markMessagesAsRead(
                                  conv['room_id'],
                                );
                                if (context.mounted) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Inbox(
                                        roomId: conv['room_id'],
                                        recipientName: conv['name'],
                                      ),
                                    ),
                                  );
                                  _loadInbox();
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatSheet,
        backgroundColor: const Color(0xFF00A36C),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.chat_bubble_outline_rounded),
      ),
    );
  }
}
