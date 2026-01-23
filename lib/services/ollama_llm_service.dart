import 'dart:async';
import 'dart:convert';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/ollama_toolkit/ollama_toolkit.dart';
import 'package:private_chat_hub/services/llm_service.dart';
import 'package:private_chat_hub/services/ollama_connection_manager.dart';

/// LLM service implementation for Ollama remote server
///
/// This wraps the existing Ollama functionality to conform to the
/// [LLMService] interface for seamless integration with the hybrid mode.
class OllamaLLMService implements LLMService {
  final OllamaConnectionManager _connectionManager;

  String? _currentModelId;

  OllamaLLMService(this._connectionManager);

  @override
  String? get currentModelId => _currentModelId;

  @override
  bool isModelLoaded(String modelId) {
    // Ollama keeps models in memory on the server
    // We just track what model we last used
    return _currentModelId == modelId;
  }

  @override
  Future<bool> isAvailable() async {
    final client = _connectionManager.client;
    if (client == null) return false;

    try {
      // Try to list models to verify connection
      await client.listModels();
      return true;
    } catch (e) {
      _log('Ollama not available: $e');
      return false;
    }
  }

  @override
  Future<List<ModelInfo>> getAvailableModels() async {
    final client = _connectionManager.client;
    if (client == null) return [];

    try {
      final response = await client.listModels();
      return response.models.map((model) {
        return ModelInfo(
          id: model.name,
          name: model.name,
          description: _getModelDescription(model),
          sizeBytes: model.size,
          isDownloaded: true, // Ollama models are always "downloaded" on server
          capabilities: _getModelCapabilities(model.name),
        );
      }).toList();
    } catch (e) {
      _log('Failed to get Ollama models: $e');
      return [];
    }
  }

  @override
  Future<void> loadModel(String modelId) async {
    // Ollama loads models on demand, but we can pre-warm by doing a quick request
    _currentModelId = modelId;

    // Optionally pre-warm the model (Ollama will load it on first request)
    // This is optional since Ollama auto-loads models
    _log('Model set to: $modelId');
  }

  @override
  Future<void> unloadModel() async {
    // Ollama manages model memory on the server
    // We just clear our tracking
    _currentModelId = null;
    _log('Model unloaded (tracking cleared)');
  }

  @override
  Stream<String> generateResponse({
    required String prompt,
    required String modelId,
    List<Message>? conversationHistory,
    String? systemPrompt,
    double temperature = 0.7,
    int? maxTokens,
  }) async* {
    final client = _connectionManager.client;
    if (client == null) {
      throw Exception('Ollama not connected');
    }

    _currentModelId = modelId;

    // Build messages in Ollama format
    final messages = <OllamaMessage>[];

    // Add system prompt if provided
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add(OllamaMessage(role: 'system', content: systemPrompt));
    }

    // Add conversation history
    if (conversationHistory != null) {
      for (final message in conversationHistory) {
        // Convert image attachments to base64 strings
        List<String>? imageStrings;
        if (message.hasImages) {
          imageStrings = message.images
              .map((a) => base64Encode(a.data))
              .toList();
        }

        messages.add(
          OllamaMessage(
            role: message.isMe ? 'user' : 'assistant',
            content: message.text,
            images: imageStrings,
          ),
        );
      }
    }

    // Add current prompt
    messages.add(OllamaMessage(role: 'user', content: prompt));

    _log('Generating response with ${messages.length} messages');

    // Build options
    final options = <String, dynamic>{'temperature': temperature};
    if (maxTokens != null) {
      options['num_predict'] = maxTokens;
    }

    // Stream the response
    try {
      await for (final response in client.chatStream(
        modelId,
        messages,
        options: options,
      )) {
        if (response.message.content.isNotEmpty) {
          yield response.message.content;
        }
      }
    } catch (e) {
      _log('Generation error: $e');
      rethrow;
    }
  }

  /// Get a description for the model based on its name
  String _getModelDescription(OllamaModelInfo model) {
    final name = model.name.toLowerCase();

    if (name.contains('llama')) {
      return 'Meta Llama model - great for general conversation and reasoning';
    } else if (name.contains('gemma')) {
      return 'Google Gemma model - efficient and capable';
    } else if (name.contains('mistral')) {
      return 'Mistral AI model - fast and powerful';
    } else if (name.contains('codellama') || name.contains('deepseek-coder')) {
      return 'Code-focused model - optimized for programming tasks';
    } else if (name.contains('phi')) {
      return 'Microsoft Phi model - efficient reasoning';
    } else if (name.contains('qwen')) {
      return 'Alibaba Qwen model - multilingual and capable';
    } else if (name.contains('llava') || name.contains('bakllava')) {
      return 'Vision model - can understand images';
    } else {
      return 'Size: ${model.sizeFormatted}';
    }
  }

  /// Get capabilities based on model name
  List<String> _getModelCapabilities(String modelName) {
    final name = modelName.toLowerCase();
    final capabilities = <String>['text'];

    // Vision models
    if (name.contains('llava') ||
        name.contains('bakllava') ||
        name.contains('gemma-3n') ||
        name.contains('minicpm-v')) {
      capabilities.add('vision');
    }

    // Tool calling models (most recent models support this)
    if (name.contains('llama3') ||
        name.contains('gemma') ||
        name.contains('qwen') ||
        name.contains('mistral') ||
        name.contains('phi')) {
      capabilities.add('tools');
    }

    return capabilities;
  }

  @override
  Future<void> dispose() async {
    // Nothing to dispose - connection is managed by OllamaConnectionManager
    _currentModelId = null;
  }

  void _log(String message) {
    // ignore: avoid_print
    print('[OllamaLLMService] $message');
  }
}
