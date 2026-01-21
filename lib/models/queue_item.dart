/// Represents a queued message waiting to be sent when connection is restored.
import 'package:private_chat_hub/models/ai_provider.dart';

class QueueItem {
  final String id;
  final String conversationId;
  final String messageId;
  final AiProviderType providerType;
  final DateTime queuedAt;
  final int retryCount;
  final DateTime? lastRetryAt;
  final String? errorMessage;

  const QueueItem({
    required this.id,
    required this.conversationId,
    required this.messageId,
    required this.providerType,
    required this.queuedAt,
    this.retryCount = 0,
    this.lastRetryAt,
    this.errorMessage,
  });

  /// Creates a QueueItem from JSON.
  factory QueueItem.fromJson(Map<String, dynamic> json) {
    return QueueItem(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      messageId: json['messageId'] as String,
      providerType: parseAiProviderType(json['providerType'] as String?),
      queuedAt: DateTime.parse(json['queuedAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      lastRetryAt: json['lastRetryAt'] != null
          ? DateTime.parse(json['lastRetryAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Converts QueueItem to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'messageId': messageId,
      'providerType': providerType.name,
      'queuedAt': queuedAt.toIso8601String(),
      'retryCount': retryCount,
      'lastRetryAt': lastRetryAt?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  /// Creates a copy with updated fields.
  QueueItem copyWith({
    String? id,
    String? conversationId,
    String? messageId,
    AiProviderType? providerType,
    DateTime? queuedAt,
    int? retryCount,
    DateTime? lastRetryAt,
    String? errorMessage,
  }) {
    return QueueItem(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      messageId: messageId ?? this.messageId,
      providerType: providerType ?? this.providerType,
      queuedAt: queuedAt ?? this.queuedAt,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueueItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Exception thrown when the message queue is full.
class QueueFullException implements Exception {
  final String message;

  QueueFullException(this.message);

  @override
  String toString() => 'QueueFullException: $message';
}
