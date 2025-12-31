import 'package:flutter/material.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:intl/intl.dart';

/// A chat message bubble widget.
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool showTimestamp;

  const MessageBubble({
    super.key,
    required this.message,
    this.showTimestamp = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMe = message.isMe;

    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (showTimestamp)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                _formatTimestamp(message.timestamp),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ),
        Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.secondary,
                child: const Icon(Icons.person, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMe ? colorScheme.primary : Colors.grey[300],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(message.timestamp),
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              const Icon(Icons.done_all, size: 16, color: Colors.blue),
            ],
          ],
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }
}
