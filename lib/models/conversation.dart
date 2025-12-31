import 'package:private_chat_hub/models/message.dart';

/// Represents a conversation with an AI model.
class Conversation {
  final String id;
  final String title;
  final String modelName;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? systemPrompt;

  const Conversation({
    required this.id,
    required this.title,
    required this.modelName,
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
    this.systemPrompt,
  });

  /// Creates a Conversation from JSON map.
  factory Conversation.fromJson(Map<String, dynamic> json) {
    final messagesList = json['messages'] as List<dynamic>? ?? [];
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String,
      modelName: json['modelName'] as String,
      messages: messagesList
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      systemPrompt: json['systemPrompt'] as String?,
    );
  }

  /// Converts Conversation to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'modelName': modelName,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'systemPrompt': systemPrompt,
    };
  }

  /// Gets the last message preview for display.
  String get lastMessagePreview {
    if (messages.isEmpty) return 'No messages yet';
    final lastMessage = messages.last;
    final text = lastMessage.text;
    if (text.length > 50) {
      return '${text.substring(0, 50)}...';
    }
    return text;
  }

  /// Gets the message count.
  int get messageCount => messages.length;

  /// Creates a copy with updated fields.
  Conversation copyWith({
    String? id,
    String? title,
    String? modelName,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? systemPrompt,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      modelName: modelName ?? this.modelName,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      systemPrompt: systemPrompt ?? this.systemPrompt,
    );
  }

  /// Adds a message to the conversation.
  Conversation addMessage(Message message) {
    return copyWith(
      messages: [...messages, message],
      updatedAt: DateTime.now(),
    );
  }

  /// Generates a title from the first user message.
  static String generateTitle(String firstMessage) {
    final cleaned = firstMessage.trim();
    if (cleaned.length <= 40) return cleaned;
    return '${cleaned.substring(0, 40)}...';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
