import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:provider/provider.dart';
import 'package:klockerapp/providers/user_provider.dart';

class InboxList extends StatefulWidget {
  final Function(String roomId, String recipientName)? onChatTap;

  const InboxList({super.key, this.onChatTap});

  @override
  State<InboxList> createState() => _InboxListState();
}

class _InboxListState extends State<InboxList> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];
  RealtimeChannel? _inboxChannel;

  @override
  void initState() {
    super.initState();
    _loadInbox();
    _subscribeToUpdates();
  }

  void _subscribeToUpdates() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _inboxChannel = Supabase.instance.client
        .channel(
          'inbox_updates_${DateTime.now().millisecondsSinceEpoch}',
        ) // unique name, avoids any collision with a stale channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            debugPrint('📬 Inbox realtime event fired: ${payload.newRecord}');
            if (mounted) _loadInbox();
          },
        )
        .subscribe((status, [error]) {
          debugPrint('📡 Inbox channel status: $status ${error ?? ""}');
        });
  }

  @override
  void dispose() {
    _inboxChannel?.unsubscribe();
    super.dispose();
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
                              final nav = Navigator.of(context);
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );

                              nav.pop();

                              showDialog(
                                context: this.context,
                                barrierDismissible: false,
                                builder: (ctx) => const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF00A36C),
                                  ),
                                ),
                              );

                              try {
                                final roomsResponse = await Supabase
                                    .instance
                                    .client
                                    .from('chat_rooms')
                                    .select('id, user_one, user_two')
                                    .or(
                                      'user_one.eq.$currentUserId,user_two.eq.$currentUserId',
                                    );

                                String? existingRoomId;

                                for (var room in roomsResponse) {
                                  if (room['user_one'] == employee['id'] ||
                                      room['user_two'] == employee['id']) {
                                    existingRoomId = room['id'];
                                    break;
                                  }
                                }

                                String finalRoomId;

                                if (existingRoomId != null) {
                                  finalRoomId = existingRoomId;
                                } else {
                                  final newRoom = await Supabase.instance.client
                                      .from('chat_rooms')
                                      .insert({
                                        'user_one': currentUserId,
                                        'user_two': employee['id'],
                                        'tenant_id': employee['tenant_id'],
                                      })
                                      .select('id')
                                      .single();
                                  finalRoomId = newRoom['id'];
                                }

                                if (this.context.mounted) {
                                  nav.pop();

                                  // Instantly update the right pane view
                                  if (widget.onChatTap != null) {
                                    widget.onChatTap!(
                                      finalRoomId,
                                      employee['full_name'] ?? 'Co-worker',
                                    );
                                  }
                                  _loadInbox();
                                }
                              } catch (e) {
                                if (this.context.mounted) {
                                  nav.pop();
                                  scaffoldMessenger.showSnackBar(
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
    final chatReady = context.watch<UserProvider>().isChatReady; // 🚀 new

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inbox',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body:
          !chatReady // 🚀 new
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00A36C)),
                  SizedBox(height: 16),
                  Text(
                    'Setting up secure chat…',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : _isLoading
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
                              onTap: () {
                                if (widget.onChatTap != null) {
                                  widget.onChatTap!(
                                    conv['room_id'],
                                    conv['name'],
                                  );
                                }

                                SupabaseService()
                                    .markMessagesAsRead(conv['room_id'])
                                    .then((_) {
                                      if (mounted) _loadInbox();
                                    })
                                    .catchError((e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Could not mark as read: $e",
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    });
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: _showNewChatSheet,
        backgroundColor: const Color(0xFF00A36C),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.chat_bubble_outline_rounded),
      ),
    );
  }
}
