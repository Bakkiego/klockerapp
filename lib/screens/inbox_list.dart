import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:provider/provider.dart';
import 'package:klockerapp/providers/user_provider.dart';

import '../utils/custom_theme/k_palette.dart';

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

  // ==========================================
  // Helpers
  // ==========================================

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: isError
              ? theme.textTheme.bodyMedium?.copyWith(color: scheme.onError)
              : null,
        ),
        backgroundColor: isError ? scheme.error : null,
      ),
    );
  }

  /// First letter for an avatar fallback. `name[0]` throws a RangeError on
  /// an empty string, which a profile saved with a blank name produces.
  static String _initial(dynamic name) {
    final text = name?.toString().trim() ?? '';
    return text.isEmpty ? 'U' : text[0].toUpperCase();
  }

  /// `time` may arrive as a DateTime or an ISO string, and Postgres hands
  /// timestamps back in UTC — so normalise and convert before comparing
  /// against "today".
  static DateTime? _localTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  Future<void> _loadInbox() async {
    try {
      final liveData = await SupabaseService().getConversations();
      if (!mounted) return;
      setState(() => _conversations = liveData);
    } catch (e) {
      // Was unguarded: one failed fetch threw and left _isLoading true, so
      // the inbox showed a spinner that never resolved.
      debugPrint("Error loading inbox: $e");
      _showSnack("Couldn't load conversations: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markRead(String roomId) async {
    try {
      await SupabaseService().markMessagesAsRead(roomId);
      if (mounted) _loadInbox();
    } catch (e) {
      _showSnack("Could not mark as read: $e", isError: true);
    }
  }

  // ==========================================
  // New chat
  // ==========================================

  void _showNewChatSheet() {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            final theme = Theme.of(context);

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: SupabaseService().getEmployees(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "Couldn't load your team.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
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

                if (team.isEmpty) {
                  return const Center(
                    child: Text("No one else on your team yet."),
                  );
                }

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "New Conversation",
                        style: theme.textTheme.titleMedium,
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
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              backgroundImage: avatarUrl != null
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl == null
                                  ? Text(
                                      _initial(employee['full_name']),
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              employee['full_name'] ?? 'Unknown',
                              style: theme.textTheme.titleSmall,
                            ),
                            subtitle: Text(
                              employee['job_title'] ??
                                  employee['role'] ??
                                  'Staff',
                            ),
                            onTap: () {
                              // Close the sheet with its OWN navigator, then
                              // hand off. The old code reused one captured
                              // navigator for both the sheet and the loading
                              // dialog, which only worked by coincidence.
                              Navigator.of(sheetContext).pop();
                              _openChatWith(employee, currentUserId);
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

  Future<void> _openChatWith(
    Map<String, dynamic> employee,
    String? currentUserId,
  ) async {
    if (!mounted || currentUserId == null) return;

    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final roomsResponse = await Supabase.instance.client
          .from('chat_rooms')
          .select('id, user_one, user_two')
          .or('user_one.eq.$currentUserId,user_two.eq.$currentUserId');

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

      navigator.pop(); // close the loading dialog
      if (!mounted) return;

      // Instantly update the right pane view
      widget.onChatTap?.call(finalRoomId, employee['full_name'] ?? 'Co-worker');
      _loadInbox();
    } catch (e) {
      navigator.pop();
      _showSnack("Error launching chat: $e", isError: true);
    }
  }

  // ==========================================
  // Build
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chatReady = context.watch<UserProvider>().isChatReady; // 🚀 new

    final Widget body;

    if (!chatReady) {
      // 🚀 new
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Setting up secure chat…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    } else if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = RefreshIndicator(
        onRefresh: _loadInbox,
        child: _conversations.isEmpty
            // A Center isn't scrollable, so pull-to-refresh did nothing on
            // an empty inbox. A one-child ListView gives it something to pull.
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(
                      child: Text(
                        "No conversations yet. Tap + to start one!",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: _conversations.length,
                itemBuilder: (context, index) =>
                    _buildConversationTile(theme, _conversations[index]),
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: body,
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: _showNewChatSheet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.chat_bubble_outline_rounded),
      ),
    );
  }

  Widget _buildConversationTile(ThemeData theme, Map<String, dynamic> conv) {
    final scheme = theme.colorScheme;

    // Both of these were read as non-null (`conv['unreadCount']` into an int,
    // `conv['lastMessage']` straight into Text).
    final int unreadCount = (conv['unreadCount'] as num?)?.toInt() ?? 0;
    final bool isUnread = unreadCount > 0;
    final String? avatarUrl = conv['avatar_url'];
    final String name = conv['name']?.toString() ?? 'Unknown';
    final String lastMessage = conv['lastMessage']?.toString() ?? '';

    String timeDisplay = '';
    final msgTime = _localTime(conv['time']);
    if (msgTime != null) {
      final now = DateTime.now();
      final isToday =
          msgTime.day == now.day &&
          msgTime.month == now.month &&
          msgTime.year == now.year;
      timeDisplay = DateFormat(isToday ? 'h:mm a' : 'MMM d').format(msgTime);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Container(
        decoration: BoxDecoration(
          color: isUnread ? scheme.surfaceContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: scheme.primaryContainer,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    _initial(name),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
          title: Text(
            name,
            style: isUnread
                ? theme.textTheme.titleSmall
                : theme.textTheme.bodyLarge,
          ),
          subtitle: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isUnread ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeDisplay,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isUnread ? context.brandText : scheme.onSurfaceVariant,
                  letterSpacing: 0,
                ),
              ),
              if (isUnread)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: scheme.primary,
                    child: Text(
                      // 3 digits don't fit an 18px circle.
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimary,
                        fontSize: 9,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          onTap: () {
            final roomId = conv['room_id']?.toString();
            if (roomId == null) return;

            widget.onChatTap?.call(roomId, name);
            _markRead(roomId);
          },
        ),
      ),
    );
  }
}
