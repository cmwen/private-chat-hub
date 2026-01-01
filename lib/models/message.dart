import 'dart:convert';
import 'dart:typed_data';
import 'package:private_chat_hub/models/tool.dart';

/// The role of a message sender.
enum MessageRole { user, assistant, system, tool }

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

  /// Whether this attachment is a text file.
  bool get isTextFile =>
      !isImage &&
      (mimeType.startsWith('text/') || mimeType == 'application/json');

  /// Gets the text content of this attachment (if it's a text file).
  String? get textContent {
    if (!isTextFile) return null;
    try {
      return utf8.decode(data);
    } catch (_) {
      return null;
    }
  }

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
  final List<ToolCall>? toolCalls;
  final String? toolCallId;

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
    this.toolCalls,
    this.toolCallId,
  });

  /// Whether this message has image attachments.
  bool get hasImages => attachments.any((a) => a.isImage);

  /// Whether this message has text file attachments.
  bool get hasTextFiles => attachments.any((a) => a.isTextFile);

  /// Gets all image attachments.
  List<Attachment> get images => attachments.where((a) => a.isImage).toList();

  /// Gets all text file attachments.
  List<Attachment> get textFiles =>
      attachments.where((a) => a.isTextFile).toList();

  /// Whether this message contains tool calls.
  bool get hasToolCalls => toolCalls != null && toolCalls!.isNotEmpty;

  /// Whether this message is a tool result.
  bool get isToolResult => role == MessageRole.tool && toolCallId != null;

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

  /// Creates a tool result message.
  factory Message.toolResult({
    required String id,
    required String toolCallId,
    required String content,
    required DateTime timestamp,
  }) {
    return Message(
      id: id,
      text: content,
      isMe: false,
      timestamp: timestamp,
      role: MessageRole.tool,
      toolCallId: toolCallId,
    );
  }

  /// Creates a Message from JSON map.
  factory Message.fromJson(Map<String, dynamic> json) {
    final attachmentsJson = json['attachments'] as List<dynamic>?;
    final toolCallsJson = json['toolCalls'] as List<dynamic>?;
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
      attachments:
          attachmentsJson
              ?.map((a) => Attachment.fromJson(a as Map<String, dynamic>))
              .toList() ??
          const [],
      toolCalls: toolCallsJson
          ?.map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
          .toList(),
      toolCallId: json['toolCallId'] as String?,
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
      if (toolCalls != null)
        'toolCalls': toolCalls!.map((tc) => tc.toJson()).toList(),
      if (toolCallId != null) 'toolCallId': toolCallId,
    };
  }

  /// Converts to Ollama API message format.
  Map<String, dynamic> toOllamaMessage() {
    // Build content with text files included
    var content = text;

    // Append text file contents to the message
    if (hasTextFiles) {
      final buffer = StringBuffer(text);
      for (final file in textFiles) {
        final fileContent = file.textContent;
        if (fileContent != null) {
          buffer.writeln();
          buffer.writeln();
          buffer.writeln('--- File: ${file.name} ---');
          buffer.writeln(fileContent);
          buffer.writeln('--- End of ${file.name} ---');
        }
      }
      content = buffer.toString();
    }

    final msg = <String, dynamic>{'role': role.name, 'content': content};

    // Add images for vision models
    if (hasImages) {
      msg['images'] = images.map((img) => base64Encode(img.data)).toList();
    }

    // Add tool calls if present
    if (hasToolCalls) {
      msg['tool_calls'] = toolCalls!
          .map(
            (tc) => {
              'id': tc.id,
              'type': 'function',
              'function': {'name': tc.name, 'arguments': tc.arguments},
            },
          )
          .toList();
    }

    // Add tool call ID for tool result messages
    if (isToolResult && toolCallId != null) {
      msg['tool_call_id'] = toolCallId;
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
    List<ToolCall>? toolCalls,
    String? toolCallId,
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
      toolCalls: toolCalls ?? this.toolCalls,
      toolCallId: toolCallId ?? this.toolCallId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
