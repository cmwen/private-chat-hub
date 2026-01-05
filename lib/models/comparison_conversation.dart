import 'package:private_chat_hub/models/conversation.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/ollama_toolkit/models/ollama_model.dart';

/// Represents a conversation comparing two AI models side-by-side.
class ComparisonConversation extends Conversation {
  final String model2Name;
  final ModelParameters parameters2;

  const ComparisonConversation({
    required super.id,
    required super.title,
    required super.modelName, // model1
    required this.model2Name,
    super.messages = const [],
    required super.createdAt,
    required super.updatedAt,
    super.systemPrompt,
    super.parameters, // parameters for model1
    ModelParameters? parameters2,
    super.projectId,
  }) : parameters2 = parameters2 ?? const ModelParameters();

  /// Whether this is a comparison conversation.
  bool get isComparisonMode => true;

  /// Gets model1 name (alias for modelName).
  String get model1Name => modelName;

  /// Gets parameters for model1 (alias for parameters).
  ModelParameters get parameters1 => parameters;

  /// Gets messages from model1 only.
  List<Message> get model1Messages =>
      messages.where((m) => m.modelSource == ModelSource.model1).toList();

  /// Gets messages from model2 only.
  List<Message> get model2Messages =>
      messages.where((m) => m.modelSource == ModelSource.model2).toList();

  /// Gets user messages (shared between both models).
  List<Message> get userMessages =>
      messages.where((m) => m.modelSource == ModelSource.user).toList();

  /// Gets the capabilities of model1.
  ModelCapabilities get model1Capabilities {
    return ModelRegistry.getCapabilities(model1Name) ??
        const ModelCapabilities(
          supportsToolCalling: false,
          supportsVision: false,
          supportsThinking: false,
          contextWindow: 4096,
          description: 'Unknown model',
        );
  }

  /// Gets the capabilities of model2.
  ModelCapabilities get model2Capabilities {
    return ModelRegistry.getCapabilities(model2Name) ??
        const ModelCapabilities(
          supportsToolCalling: false,
          supportsVision: false,
          supportsThinking: false,
          contextWindow: 4096,
          description: 'Unknown model',
        );
  }

  /// Creates a ComparisonConversation from JSON map.
  factory ComparisonConversation.fromJson(Map<String, dynamic> json) {
    final messagesList = json['messages'] as List<dynamic>? ?? [];
    return ComparisonConversation(
      id: json['id'] as String,
      title: json['title'] as String,
      modelName: json['modelName'] as String,
      model2Name: json['model2Name'] as String,
      messages: messagesList
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      systemPrompt: json['systemPrompt'] as String?,
      parameters: json['parameters'] != null
          ? ModelParameters.fromJson(json['parameters'] as Map<String, dynamic>)
          : const ModelParameters(),
      parameters2: json['parameters2'] != null
          ? ModelParameters.fromJson(
              json['parameters2'] as Map<String, dynamic>,
            )
          : const ModelParameters(),
      projectId: json['projectId'] as String?,
    );
  }

  /// Converts ComparisonConversation to JSON map.
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['model2Name'] = model2Name;
    json['parameters2'] = parameters2.toJson();
    json['isComparisonMode'] = true;
    return json;
  }

  /// Creates a copy with updated fields.
  @override
  ComparisonConversation copyWith({
    String? id,
    String? title,
    String? modelName,
    String? model2Name,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? systemPrompt,
    ModelParameters? parameters,
    ModelParameters? parameters2,
    String? projectId,
    bool clearProjectId = false,
  }) {
    return ComparisonConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      modelName: modelName ?? this.modelName,
      model2Name: model2Name ?? this.model2Name,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      parameters: parameters ?? this.parameters,
      parameters2: parameters2 ?? this.parameters2,
      projectId: clearProjectId ? null : (projectId ?? this.projectId),
    );
  }

  /// Gets the last message preview for display.
  @override
  String get lastMessagePreview {
    if (messages.isEmpty) return 'Comparing $model1Name vs $model2Name';

    // Show the last user message if available
    final userMsgs = messages.where((m) => m.isMe).toList();
    if (userMsgs.isNotEmpty) {
      final text = userMsgs.last.text;
      if (text.length > 40) {
        return '${text.substring(0, 40)}...';
      }
      return text;
    }

    return 'Comparing models...';
  }
}
