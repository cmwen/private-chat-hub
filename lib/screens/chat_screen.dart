import 'package:flutter/material.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/widgets/message_bubble.dart';
import 'package:private_chat_hub/widgets/message_input.dart';

/// Main chat screen displaying messages and input field.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load sample messages for demonstration.
  void _loadInitialMessages() {
    setState(() {
      _messages.addAll([
        Message(
          id: '1',
          text: 'Hey! How are you?',
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        Message(
          id: '2',
          text: 'I\'m doing great! Thanks for asking.',
          isMe: true,
          timestamp: DateTime.now().subtract(const Duration(minutes: 9)),
        ),
        Message(
          id: '3',
          text: 'Want to grab coffee later?',
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ]);
    });
  }

  /// Handles sending a new message.
  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;

    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(newMessage);
    });

    // Scroll to bottom after adding message
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.blueAccent),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Private Chat', style: TextStyle(fontSize: 16)),
                Text(
                  'Online',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {},
            tooltip: 'Video call',
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {},
            tooltip: 'Voice call',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
            tooltip: 'More options',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final showTimestamp =
                          index == 0 ||
                          _messages[index - 1].timestamp
                                  .difference(message.timestamp)
                                  .inMinutes
                                  .abs() >
                              5;

                      return MessageBubble(
                        message: message,
                        showTimestamp: showTimestamp,
                      );
                    },
                  ),
          ),
          MessageInput(onSendMessage: _handleSendMessage),
        ],
      ),
    );
  }
}
