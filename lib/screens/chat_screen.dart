import 'package:flutter/material.dart';

// Represents a single message
class Message {
  final String text;
  final bool isUser; // True if message is from the current user
  final DateTime time;

  Message({required this.text, required this.isUser, required this.time});
}

class ChatScreen extends StatefulWidget {
  final String recipientName;

  const ChatScreen({super.key, required this.recipientName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Mock message history
  final List<Message> _messages = [
    Message(
      text: "Hi! How's the project tracking going?",
      isUser: false, // Initial message from the recipient
      time: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    Message(
      text:
          "Everything looks good on my end. I'm finalizing the Q3 report now.",
      isUser: true,
      time: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    Message(
      text: "Great! Let me know when you drop it in the shared drive.",
      isUser: false,
      time: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
  ];

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        Message(
          text: text,
          isUser: true, // New message is always from the current user
          time: DateTime.now(),
        ),
      );
    });
    _textController.clear();

    // Scroll to the latest message after the widget has been rebuilt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recipientName)),
      body: Column(
        children: [
          // 1. Message List Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemCount: _messages.length,
              itemBuilder: (_, index) =>
                  _MessageBubble(message: _messages[index]),
            ),
          ),
          const Divider(height: 1.0),

          // 2. Message Input Area
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  // Input Field Composer
  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          // Attachment Button
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.grey),
            onPressed: () {
              // TODO: Handle file attachment
            },
          ),
          // Text Input Field
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: const InputDecoration.collapsed(
                hintText: "Send a message...",
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          // Send Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: IconButton(
              icon: Icon(
                Icons.send,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Widget for a single message bubble
class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          // Message Bubble
          Container(
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.of(context).size.width * 0.75, // Max 75% width
            ),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: isUser ? primaryColor : Colors.grey.shade200,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16.0),
                topRight: const Radius.circular(16.0),
                // Point the corner towards the avatar/edge
                bottomLeft: isUser
                    ? const Radius.circular(16.0)
                    : const Radius.circular(4.0),
                bottomRight: isUser
                    ? const Radius.circular(4.0)
                    : const Radius.circular(16.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 15.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  // Format time to HH:MM
                  '${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 10.0,
                    color: isUser ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
