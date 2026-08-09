import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime time;

  Message({required this.text, required this.isUser, required this.time});
}

class ChatScreen extends StatefulWidget {
  final String? recipientName;
  final String? roomId;

  const ChatScreen({super.key, this.recipientName, this.roomId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final supabase = Supabase.instance.client;

  List<Message> _messages = [];
  bool _isLoading = false;
  late final String _currentUserId;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;

  @override
  void initState() {
    super.initState();
    _currentUserId = supabase.auth.currentUser!.id;
    if (widget.roomId != null) {
      _initChat(widget.roomId!);
    }
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.roomId != oldWidget.roomId) {
      _messagesSub?.cancel();
      if (widget.roomId != null) {
        setState(() => _isLoading = true);
        _initChat(widget.roomId!);
      } else {
        setState(() {
          _messages = [];
          _isLoading = false;
        });
      }
    }
  }

  void _initChat(String roomId) {
    setState(() => _isLoading = true);
    _messagesSub = SupabaseService()
        .getLiveMessagesStream(roomId)
        .listen(
          (rows) {
            if (!mounted) return;
            setState(() {
              _messages = rows
                  .map<Message>(
                    (row) => Message(
                      text: row['message_text'] ?? '',
                      isUser: row['sender_id'] == _currentUserId,
                      time: DateTime.parse(row['created_at']).toLocal(),
                    ),
                  )
                  .toList();
              _isLoading = false;
            });
            _scrollToBottom();
          },
          onError: (e) {
            debugPrint('Error loading chat stream: $e');
            if (mounted) setState(() => _isLoading = false);
          },
        );
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty || widget.roomId == null) return;
    final messageText = text.trim();
    _textController.clear();

    final tempMessage = Message(
      text: messageText,
      isUser: true,
      time: DateTime.now(),
    );
    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      await SupabaseService().sendMessage(
        roomId: widget.roomId!,
        text: messageText,
      );
    } catch (error) {
      debugPrint('Send error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send: $error"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() {
          _messages.remove(tempMessage);
        });
      }
    }
  }

  void _scrollToBottom() {
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
    _messagesSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.roomId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF13151A),
        body: Center(
          child: Text(
            'Select a conversation to start chatting',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF13151A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13151A),
        elevation: 0,
        title: Text(widget.recipientName ?? 'Chat'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _messages.length,
                        itemBuilder: (_, index) =>
                            _MessageBubble(message: _messages[index]),
                      ),
              ),
              Container(
                decoration: const BoxDecoration(color: Color(0xFF13151A)),
                child: _buildTextComposer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2329),
                borderRadius: BorderRadius.circular(30.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sentiment_satisfied_alt,
                    color: Colors.grey[500],
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: _handleSubmitted,
                      minLines: 1,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: "Type a message here...",
                        hintStyle: TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.attach_file_rounded,
                    color: Colors.grey[500],
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF00A36C),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isUser ? primaryColor : Colors.grey.shade900,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16.0),
            topRight: const Radius.circular(16.0),
            bottomLeft: isUser
                ? const Radius.circular(16.0)
                : const Radius.circular(4.0),
            bottomRight: isUser
                ? const Radius.circular(4.0)
                : const Radius.circular(16.0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.white70,
                fontSize: 15.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10.0,
                color: isUser ? Colors.white70 : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
