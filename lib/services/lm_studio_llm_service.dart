import 'dart:async';

import 'package:private_chat_hub/models/lm_studio_models.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/services/llm_service.dart';
import 'package:private_chat_hub/services/lm_studio_connection_manager.dart';

/// LLM service implementation for LM Studio servers.
class LmStudioLLMService implements LLMService {
  final LmStudioConnectionManager _connectionManager;

  String? _currentModelId;

  LmStudioLLMService(this._connectionManager);

  @override
  String? get currentModelId => _currentModelId;

  @override
  bool isModelLoaded(String modelId) => _currentModelId == modelId;

  bool get hasConfiguredConnection => _connectionManager.connection != null;

  String? get activeConnectionName => _connectionManager.connection?.name;

  @override
  Future<bool> isAvailable() async {
    return _connectionManager.testConnection();
  }

  @override
  Future<List<ModelInfo>> getAvailableModels() async {
    final response = await _connectionManager.client.listModels();

    return response.models
        .where((model) => model.isLlm)
        .map(_toModelInfo)
        .toList();
  }

  @override
  Future<void> loadModel(String modelId) async {
    _currentModelId = modelId;
  }

  @override
  Future<void> unloadModel() async {
    _currentModelId = null;
  }

  @override
  Stream<String> generateResponse({
    required String prompt,
    required String modelId,
    List<Message>? conversationHistory,
    String? systemPrompt,
    double temperature = 0.7,
    int? maxTokens,
    List<Attachment>? attachments,
  }) async* {
    _currentModelId = modelId;

    final resolvedPrompt = _buildPrompt(
      prompt: prompt,
      conversationHistory: conversationHistory,
      systemPrompt: systemPrompt,
    );

    var yieldedAnyContent = false;
    LmStudioChatResult? finalResult;

    try {
      await for (final event in _connectionManager.client.chatStream(
        modelId: _stripPrefix(modelId),
        prompt: resolvedPrompt,
        attachments: attachments,
        systemPrompt: systemPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
      )) {
        switch (event.type) {
          case 'message.delta':
            final content = event.data['content'] as String? ?? '';
            if (content.isNotEmpty) {
              yieldedAnyContent = true;
              yield content;
            }
          case 'chat.end':
            final result = event.data['result'];
            if (result is Map<String, dynamic>) {
              finalResult = LmStudioChatResult.fromJson(result);
            }
          case 'error':
            final error = event.data['error'];
            if (error is Map<String, dynamic>) {
              final message =
                  error['message'] as String? ?? 'Unknown LM Studio error';
              throw Exception(message);
            }
        }
      }

      if (!yieldedAnyContent && finalResult != null) {
        final text = _extractMessageText(finalResult);
        if (text.isNotEmpty) {
          yield text;
          return;
        }
      }
    } catch (_) {
      final response = await _connectionManager.client.chat(
        modelId: _stripPrefix(modelId),
        prompt: resolvedPrompt,
        attachments: attachments,
        systemPrompt: systemPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
      );
      final text = _extractMessageText(response);
      if (text.isNotEmpty) {
        yield text;
      }
    }
  }

  @override
  Future<void> dispose() async {
    _currentModelId = null;
  }

  ModelInfo _toModelInfo(LmStudioModel model) {
    final capabilities = <String>['text'];
    if (model.capabilities?.vision == true) {
      capabilities.add('vision');
    }
    if (model.capabilities?.trainedForToolUse == true) {
      capabilities.add('tools');
    }

    final details = <String>[
      if (model.publisher.isNotEmpty) model.publisher,
      if (model.paramsString != null && model.paramsString!.isNotEmpty)
        model.paramsString!,
      if (model.maxContextLength != null) '${model.maxContextLength} ctx',
    ];

    return ModelInfo(
      id: 'lmstudio:${model.key}',
      name: model.displayName,
      description: model.description?.trim().isNotEmpty == true
          ? model.description!
          : details.join(' · '),
      sizeBytes: model.sizeBytes,
      isDownloaded: true,
      capabilities: capabilities,
      isLocal: false,
    );
  }

  String _stripPrefix(String modelId) {
    if (modelId.startsWith('lmstudio:')) {
      return modelId.substring('lmstudio:'.length);
    }
    return modelId;
  }

  String _buildPrompt({
    required String prompt,
    List<Message>? conversationHistory,
    String? systemPrompt,
  }) {
    if ((conversationHistory == null || conversationHistory.isEmpty) &&
        (systemPrompt == null || systemPrompt.trim().isEmpty)) {
      return prompt;
    }

    final buffer = StringBuffer();
    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      buffer.writeln('System: ${systemPrompt.trim()}');
      buffer.writeln();
    }

    for (final message in conversationHistory ?? const <Message>[]) {
      final role = switch (message.role) {
        MessageRole.user => 'User',
        MessageRole.assistant => 'Assistant',
        MessageRole.system => 'System',
        MessageRole.tool => 'Tool',
      };
      if (message.text.trim().isEmpty) {
        continue;
      }
      buffer.writeln('$role: ${message.text.trim()}');
    }

    buffer.writeln('User: $prompt');
    return buffer.toString().trim();
  }

  String _extractMessageText(LmStudioChatResult result) {
    final buffer = StringBuffer();
    for (final item in result.output) {
      if (item['type'] == 'message') {
        final content = item['content'] as String? ?? '';
        if (content.isNotEmpty) {
          buffer.write(content);
        }
      }
    }
    return buffer.toString();
  }
}
