import 'package:flutter/material.dart';
import 'inbox_list.dart';
import 'inbox.dart';

class ChatDashboard extends StatefulWidget {
  const ChatDashboard({super.key});

  @override
  State<ChatDashboard> createState() => _ChatDashboardState();
}

class _ChatDashboardState extends State<ChatDashboard> {
  String? _selectedRoomId;
  String? _selectedRecipientName;

  /// Below this the two panes don't both fit, so the chat opens as its own
  /// route instead. Matters for a browser window dragged narrow.
  static const _splitBreakpoint = 700.0;

  void _handleChatSelected(String roomId, String recipientName) {
    if (MediaQuery.of(context).size.width < _splitBreakpoint) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Inbox(roomId: roomId, recipientName: recipientName),
        ),
      );
      return;
    }

    setState(() {
      _selectedRoomId = roomId;
      _selectedRecipientName = recipientName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSplit = constraints.maxWidth >= _splitBreakpoint;

          if (!isSplit) {
            return InboxList(onChatTap: _handleChatSelected);
          }

          return Row(
            children: [
              // Left Sidebar (Fixed width)
              SizedBox(
                width: 320,
                child: InboxList(onChatTap: _handleChatSelected),
              ),

              // Subtle vertical border separator — takes its colour from
              // dividerTheme now instead of a fixed white10.
              const VerticalDivider(width: 1, thickness: 1),

              // Right Chat Screen (Fills remaining space)
              Expanded(
                child: Inbox(
                  // The key forces a fresh State per conversation, so the
                  // stream, scroll position and draft all reset cleanly.
                  key: ValueKey(_selectedRoomId ?? 'empty_chat'),
                  roomId: _selectedRoomId,
                  recipientName: _selectedRecipientName,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
