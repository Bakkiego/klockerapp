import 'package:flutter/material.dart';
import 'inbox_list.dart';
import 'chat_screen.dart';

class ChatDashboard extends StatefulWidget {
  const ChatDashboard({super.key});

  @override
  State<ChatDashboard> createState() => _ChatDashboardState();
}

class _ChatDashboardState extends State<ChatDashboard> {
  String? _selectedRoomId;
  String? _selectedRecipientName;

  void _handleChatSelected(String roomId, String recipientName) {
    setState(() {
      _selectedRoomId = roomId;
      _selectedRecipientName = recipientName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13151A),
      body: Row(
        children: [
          // Left Sidebar (Fixed width)
          SizedBox(
            width: 320,
            child: InboxList(onChatTap: _handleChatSelected),
          ),

          // Subtle vertical border separator
          Container(width: 1, color: Colors.white10),

          // Right Chat Screen (Fills remaining space)
          Expanded(
            child: ChatScreen(
              key: ValueKey(_selectedRoomId ?? 'empty_chat'),
              roomId: _selectedRoomId,
              recipientName: _selectedRecipientName,
            ),
          ),
        ],
      ),
    );
  }
}
