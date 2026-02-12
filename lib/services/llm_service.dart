import 'dart:async';
import 'package:private_chat_hub/models/message.dart';

/// Inference mode for the chat service
enum InferenceMode {
  /// Remote inference via Ollama server
  remote,

  /// On-device inference via LiteRT-LM
  onDevice,
}

/// Information about an available model
class ModelInfo {
  final String id;
  final String name;
  final String description;
  final int sizeBytes;
  final bool isDownloaded;
  final List<String> capabilities;
  final String? downloadUrl;
  final bool isLocal;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.sizeBytes,
    required this.isDownloaded,
    required this.capabilities,
    this.downloadUrl,
    this.isLocal = false,
  });

  /// Human-readable size string (e.g., "557 MB")
  String get sizeString {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Check if model supports vision input
  bool get supportsVision => capabilities.contains('vision');

  /// Check if model supports audio input
  bool get supportsAudio => capabilities.contains('audio');

  /// Check if model supports tool calling
  bool get supportsTools => capabilities.contains('tools');

  ModelInfo copyWith({
    String? id,
    String? name,
    String? description,
    int? sizeBytes,
    bool? isDownloaded,
    List<String>? capabilities,
    String? downloadUrl,
    bool? isLocal,
  }) {
    return ModelInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      capabilities: capabilities ?? this.capabilities,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sizeBytes': sizeBytes,
      'isDownloaded': isDownloaded,
      'isLocal': isLocal,
      'capabilities': capabilities,
      'downloadUrl': downloadUrl,
    };
  }

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      sizeBytes: json['sizeBytes'] as int,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      capabilities:
          (json['capabilities'] as List<dynamic>?)?.cast<String>() ?? [],
      downloadUrl: json['downloadUrl'] as String?,
    );
  }
}

/// Abstract interface for LLM services
///
/// This interface allows switching between different LLM backends
/// (e.g., Ollama remote server vs LiteRT-LM on-device).
abstract class LLMService {
  /// Stream-based text generation
  ///
  /// Returns a stream of tokens as they are generated.
  /// The stream completes when generation is finished.
  Stream<String> generateResponse({
    required String prompt,
    required String modelId,
    List<Message>? conversationHistory,
    String? systemPrompt,
    double temperature,
    int? maxTokens,
  });

  /// Check if the service is available and ready
  Future<bool> isAvailable();

  /// Get list of available models
  Future<List<ModelInfo>> getAvailableModels();

  /// Load a model for inference
  ///
  /// For on-device services, this loads the model into memory.
  /// For remote services, this may be a no-op or verify model availability.
  Future<void> loadModel(String modelId);

  /// Unload the currently loaded model
  ///
  /// Frees memory by unloading the model.
  /// For remote services, this is typically a no-op.
  Future<void> unloadModel();

  /// Get the currently loaded model ID, if any
  String? get currentModelId;

  /// Check if a specific model is loaded
  bool isModelLoaded(String modelId);

  /// Dispose of resources
  Future<void> dispose();
}

/// Configuration for LLM inference
class LLMConfig {
  final double temperature;
  final int? maxTokens;
  final double? topP;
  final int? topK;
  final String? stopSequence;

  const LLMConfig({
    this.temperature = 0.7,
    this.maxTokens,
    this.topP,
    this.topK,
    this.stopSequence,
  });

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      if (maxTokens != null) 'maxTokens': maxTokens,
      if (topP != null) 'topP': topP,
      if (topK != null) 'topK': topK,
      if (stopSequence != null) 'stopSequence': stopSequence,
    };
  }
}
