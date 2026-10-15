import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:provider/provider.dart';
import 'package:klockerapp/providers/user_provider.dart';

class Inbox extends StatefulWidget {
  final String? roomId;

  /// Nullable so the split view can mount this with no conversation picked
  /// yet. On mobile it's always supplied by the route.
  final String? recipientName;

  const Inbox({super.key, this.roomId, this.recipientName});

  @override
  State<Inbox> createState() => _InboxState();
}

class _InboxState extends State<Inbox> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _currentUserId =
      Supabase.instance.client.auth.currentUser?.id ?? '';

  Stream<List<Map<String, dynamic>>>? _messagesStream;

  /// Tracks how many messages were on screen last build, so the view only
  /// jumps when something new actually arrives.
  int _lastMessageCount = 0;

  static const _emptyChatMessage = "No messages yet. Say hi! 👋";
  static const _noRoomMessage = "Select a conversation to start chatting";

  @override
  void initState() {
    super.initState();
    _openRoom(widget.roomId);
  }

  /// In the split view this widget is never rebuilt from scratch — the same
  /// instance just gets a new roomId when another conversation is tapped.
  /// Without this the right pane would stay stuck on the first chat opened.
  @override
  void didUpdateWidget(covariant Inbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.roomId != oldWidget.roomId) {
      // A half-typed message belongs to the person you were talking to, not
      // the one you just switched to.
      _messageController.clear();
      setState(() {
        _lastMessageCount = 0;
        _messagesStream = null;
        _openRoom(widget.roomId);
      });
    }
  }

  void _openRoom(String? roomId) {
    if (roomId == null) return;
    SupabaseService().markMessagesAsRead(roomId);
    _messagesStream = SupabaseService().getLiveMessagesStream(roomId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || widget.roomId == null) return;

    _messageController.clear();

    try {
      await SupabaseService().sendMessage(roomId: widget.roomId!, text: text);
    } catch (e) {
      if (!mounted) return;

      // Put the text back — clearing before the send succeeded meant a
      // failed message was simply gone and had to be retyped.
      _messageController.text = text;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );

      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to send message: $e",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onError,
            ),
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  /// Scroll down only when a new message lands AND the reader is already at
  /// the bottom. The old version re-scrolled on every stream rebuild, which
  /// made scrolling up through history impossible — the list snapped back.
  void _maybeAutoScroll(int messageCount) {
    final hasNewMessage = messageCount > _lastMessageCount;
    _lastMessageCount = messageCount;
    if (!hasNewMessage) return;

    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final isNearBottom = position.maxScrollExtent - position.pixels < 200;
      if (!isNearBottom) return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chatReady = context.watch<UserProvider>().isChatReady; // 🚀 new

    final Widget body;

    if (!chatReady) {
      // 🚀 new — replaces the whole body while chat isn't ready
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
    } else if (widget.roomId == null) {
      // The split view's resting state, before a conversation is picked.
      body = Center(
        child: Text(
          _noRoomMessage,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    } else {
      body = Column(
        children: [
          Expanded(child: _buildMessageList(theme)),
          _buildComposer(theme),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientName ?? 'Chat'),
        centerTitle: false,
      ),
      // Stops bubbles stretching the full width of a desktop monitor.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: body,
        ),
      ),
    );
  }

  Widget _buildMessageList(ThemeData theme) {
    if (_messagesStream == null) {
      return _buildEmptyState(theme);
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                "Error loading chats: ${snapshot.error}",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!;
        _maybeAutoScroll(messages.length);

        if (messages.isEmpty) return _buildEmptyState(theme);

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) => _buildBubble(theme, messages[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) => Center(
    child: Text(
      _emptyChatMessage,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );

  Widget _buildBubble(ThemeData theme, Map<String, dynamic> msg) {
    final scheme = theme.colorScheme;
    final bool isMe = msg['sender_id'] == _currentUserId;

    String timeStr = '';
    if (msg['created_at'] != null) {
      // Postgres hands these back in UTC. Without toLocal() every message
      // was stamped two hours behind for a UTC+2 reader.
      final created = DateTime.parse(msg['created_at']).toLocal();
      timeStr = DateFormat('h:mm a').format(created);
    }

    final bubbleColor = isMe ? scheme.primary : scheme.surfaceContainer;
    final textColor = isMe ? scheme.onPrimary : scheme.onSurface;
    // Muted version of the text colour: mixed toward the bubble behind it.
    final timeColor = Color.lerp(textColor, bubbleColor, 0.35)!;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          // 75% of the screen is right on a phone, but in the split view the
          // screen is the whole window — so cap it too.
          maxWidth: math.min(MediaQuery.of(context).size.width * 0.75, 480),
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg['message_text'] ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timeStr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: timeColor,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(ThemeData theme) {
    final scheme = theme.colorScheme;

    // The chat field wants a borderless 24px pill, not the app's standard
    // 12px outlined input — so enabled/focused are overridden too. Without
    // overriding focusedBorder the global theme snaps it back to a 12px
    // green outline the moment it gains focus.
    const pill = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
      borderSide: BorderSide.none,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                // Was `null`, so a long message grew the field without limit
                // and pushed the conversation off screen.
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  filled: true,
                  fillColor: scheme.surfaceContainer,
                  border: pill,
                  enabledBorder: pill,
                  focusedBorder: pill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Rebuilds on its own so typing doesn't rebuild the whole screen.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _messageController,
              builder: (context, value, _) {
                final canSend = value.text.trim().isNotEmpty;
                return IconButton(
                  onPressed: canSend ? _sendMessage : null,
                  tooltip: "Send",
                  icon: const Icon(Icons.send_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: canSend
                        ? scheme.primary
                        : scheme.surfaceContainer,
                    foregroundColor: canSend
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                    disabledBackgroundColor: scheme.surfaceContainer,
                    disabledForegroundColor: scheme.onSurfaceVariant,
                    minimumSize: const Size(44, 44),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
