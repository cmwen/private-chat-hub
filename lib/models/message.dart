import 'dart:convert';
import 'dart:typed_data';

/// The role of a message sender.
enum MessageRole {
  user,
  assistant,
  system,
}

/// Represents an attached file or image.
class Attachment {
  final String id;
  final String name;
  final String mimeType;
  final Uint8List data;
  final int size;

  const Attachment({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.data,
    required this.size,
  });

  /// Whether this is an image attachment.
  bool get isImage => mimeType.startsWith('image/');

  /// Creates an Attachment from JSON.
  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      name: json['name'] as String,
      mimeType: json['mimeType'] as String,
      data: base64Decode(json['data'] as String),
      size: json['size'] as int,
    );
  }

  /// Converts Attachment to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mimeType': mimeType,
      'data': base64Encode(data),
      'size': size,
    };
  }

  /// Gets a human-readable file size.
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Represents a chat message in the conversation.
class Message {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final MessageRole role;
  final bool isStreaming;
  final bool isError;
  final String? errorMessage;
  final List<Attachment> attachments;

  const Message({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.role = MessageRole.user,
    this.isStreaming = false,
    this.isError = false,
    this.errorMessage,
    this.attachments = const [],
  });

  /// Whether this message has image attachments.
  bool get hasImages => attachments.any((a) => a.isImage);

  /// Gets all image attachments.
  List<Attachment> get images => attachments.where((a) => a.isImage).toList();

  /// Creates a user message.
  factory Message.user({
    required String id,
    required String text,
    required DateTime timestamp,
    List<Attachment>? attachments,
  }) {
    return Message(
      id: id,
      text: text,
      isMe: true,
      timestamp: timestamp,
      role: MessageRole.user,
      attachments: attachments ?? const [],
    );
  }

  /// Creates an assistant (AI) message.
  factory Message.assistant({
    required String id,
    required String text,
    required DateTime timestamp,
    bool isStreaming = false,
  }) {
    return Message(
      id: id,
      text: text,
      isMe: false,
      timestamp: timestamp,
      role: MessageRole.assistant,
      isStreaming: isStreaming,
    );
  }

  /// Creates a system message.
  factory Message.system({
    required String id,
    required String text,
    required DateTime timestamp,
  }) {
    return Message(
      id: id,
      text: text,
      isMe: false,
      timestamp: timestamp,
      role: MessageRole.system,
    );
  }

  /// Creates an error message.
  factory Message.error({
    required String id,
    required String errorMessage,
    required DateTime timestamp,
  }) {
    return Message(
      id: id,
      text: 'Error: $errorMessage',
      isMe: false,
      timestamp: timestamp,
      role: MessageRole.assistant,
      isError: true,
      errorMessage: errorMessage,
    );
  }

  /// Creates a Message from JSON map.
  factory Message.fromJson(Map<String, dynamic> json) {
    final attachmentsJson = json['attachments'] as List<dynamic>?;
    return Message(
      id: json['id'] as String,
      text: json['text'] as String,
      isMe: json['isMe'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      role: MessageRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => MessageRole.user,
      ),
      isStreaming: json['isStreaming'] as bool? ?? false,
      isError: json['isError'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
      attachments: attachmentsJson
          ?.map((a) => Attachment.fromJson(a as Map<String, dynamic>))
          .toList() ?? const [],
    );
  }

  /// Converts Message to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isMe': isMe,
      'timestamp': timestamp.toIso8601String(),
      'role': role.name,
      'isStreaming': isStreaming,
      'isError': isError,
      'errorMessage': errorMessage,
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }

  /// Converts to Ollama API message format.
  Map<String, dynamic> toOllamaMessage() {
    final msg = <String, dynamic>{
      'role': role.name,
      'content': text,
    };
    
    // Add images for vision models
    if (hasImages) {
      msg['images'] = images.map((img) => base64Encode(img.data)).toList();
    }
    
    return msg;
  }

  /// Creates a copy with updated text (for streaming).
  Message copyWith({
    String? id,
    String? text,
    bool? isMe,
    DateTime? timestamp,
    MessageRole? role,
    bool? isStreaming,
    bool? isError,
    String? errorMessage,
    List<Attachment>? attachments,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
      role: role ?? this.role,
      isStreaming: isStreaming ?? this.isStreaming,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

