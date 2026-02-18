import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/ollama_toolkit/models/ollama_model.dart';

/// Model parameters for controlling AI behavior.
class ModelParameters {
  final double temperature;
  final int topK;
  final double topP;
  final int maxTokens;

  const ModelParameters({
    this.temperature = 0.7,
    this.topK = 40,
    this.topP = 0.9,
    this.maxTokens = 2048,
  });

  /// Default balanced parameters.
  static const balanced = ModelParameters();

  /// Creative parameters (more random, diverse outputs).
  static const creative = ModelParameters(
    temperature: 1.2,
    topK: 60,
    topP: 0.95,
    maxTokens: 2048,
  );

  /// Precise parameters (more focused, deterministic outputs).
  static const precise = ModelParameters(
    temperature: 0.3,
    topK: 20,
    topP: 0.7,
    maxTokens: 2048,
  );

  /// Code-optimized parameters.
  static const code = ModelParameters(
    temperature: 0.2,
    topK: 10,
    topP: 0.5,
    maxTokens: 4096,
  );

  factory ModelParameters.fromJson(Map<String, dynamic> json) {
    return ModelParameters(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      topK: (json['topK'] as num?)?.toInt() ?? 40,
      topP: (json['topP'] as num?)?.toDouble() ?? 0.9,
      maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 2048,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'topK': topK,
      'topP': topP,
      'maxTokens': maxTokens,
    };
  }

  /// Converts to Ollama API options format.
  Map<String, dynamic> toOllamaOptions() {
    return {
      'temperature': temperature,
      'top_k': topK,
      'top_p': topP,
      'num_predict': maxTokens,
    };
  }

  ModelParameters copyWith({
    double? temperature,
    int? topK,
    double? topP,
    int? maxTokens,
  }) {
    return ModelParameters(
      temperature: temperature ?? this.temperature,
      topK: topK ?? this.topK,
      topP: topP ?? this.topP,
      maxTokens: maxTokens ?? this.maxTokens,
    );
  }
}

/// Represents a conversation with an AI model.
class Conversation {
  final String id;
  final String title;
  final String modelName;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? systemPrompt;
  final ModelParameters parameters;
  final String? projectId;
  final bool toolCallingEnabled;

  const Conversation({
    required this.id,
    required this.title,
    required this.modelName,
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
    this.systemPrompt,
    this.parameters = const ModelParameters(),
    this.projectId,
    this.toolCallingEnabled = true,
  });

  /// Whether this conversation belongs to a project.
  bool get hasProject => projectId != null;

  /// Gets the capabilities of the model used in this conversation.
  ModelCapabilities get modelCapabilities {
    // Strip 'local:' prefix before looking up in the registry so that
    // on-device models (e.g. 'local:gemma-3n-e2b') resolve correctly.
    final registryName = modelName.startsWith('local:')
        ? modelName.substring('local:'.length)
        : modelName;
    return ModelRegistry.getCapabilities(registryName) ??
        const ModelCapabilities(
          supportsToolCalling: false,
          supportsVision: false,
          supportsThinking: false,
          contextWindow: 4096,
          description: 'Unknown model',
        );
  }

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
      parameters: json['parameters'] != null
          ? ModelParameters.fromJson(json['parameters'] as Map<String, dynamic>)
          : const ModelParameters(),
      projectId: json['projectId'] as String?,
      toolCallingEnabled: json['toolCallingEnabled'] as bool? ?? true,
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
      'parameters': parameters.toJson(),
      'projectId': projectId,
      'toolCallingEnabled': toolCallingEnabled,
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
    ModelParameters? parameters,
    String? projectId,
    bool clearProjectId = false,
    bool? toolCallingEnabled,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      modelName: modelName ?? this.modelName,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      parameters: parameters ?? this.parameters,
      projectId: clearProjectId ? null : (projectId ?? this.projectId),
      toolCallingEnabled: toolCallingEnabled ?? this.toolCallingEnabled,
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
