/// Represents a chat message in the conversation.
class Message {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
  });

  /// Creates a Message from JSON map.
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      text: json['text'] as String,
      isMe: json['isMe'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Converts Message to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isMe': isMe,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
