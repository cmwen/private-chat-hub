import 'dart:async';
import 'dart:convert';

import 'package:private_chat_hub/models/ai_provider.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/models/provider_models.dart';
import 'package:private_chat_hub/ollama_toolkit/models/ollama_model.dart';
import 'package:private_chat_hub/ollama_toolkit/ollama_toolkit.dart';
import 'package:private_chat_hub/ollama_toolkit/models/ollama_tool.dart';
import 'package:private_chat_hub/services/lite_llm_client.dart';

class ProviderChatResponse {
  final String content;
  final List<Map<String, dynamic>>? toolCalls;

  const ProviderChatResponse({required this.content, this.toolCalls});
}

class ProviderChatChunk {
  final String contentDelta;
  final bool isDone;
  final List<Map<String, dynamic>>? toolCalls;

  const ProviderChatChunk({
    required this.contentDelta,
    required this.isDone,
    this.toolCalls,
  });
}

abstract class ProviderChatClient {
  AiProviderType get providerType;
  Future<bool> testConnection();
  Future<List<ProviderModelInfo>> listModels();
  Future<ProviderChatResponse> chat({
    required String model,
    required List<Message> messages,
    Map<String, dynamic>? options,
    List<Map<String, dynamic>>? tools,
  });
  Stream<ProviderChatChunk> chatStream({
    required String model,
    required List<Message> messages,
    Map<String, dynamic>? options,
    List<Map<String, dynamic>>? tools,
  });
}

class OllamaProviderChatClient implements ProviderChatClient {
  final OllamaClient _client;

  OllamaProviderChatClient(this._client);

  @override
  AiProviderType get providerType => AiProviderType.ollama;

  @override
  Future<bool> testConnection() => _client.testConnection();

  @override
  Future<List<ProviderModelInfo>> listModels() async {
    final response = await _client.listModels();
    return response.models
        .map(
          (model) => ProviderModelInfo(
            name: model.name,
            sizeFormatted: model.sizeFormatted,
            parameterCount: model.parameterCount,
            capabilities: model.capabilities,
          ),
        )
        .toList();
  }

  @override
  Future<ProviderChatResponse> chat({
    required String model,
    required List<Message> messages,
    Map<String, dynamic>? options,
    List<Map<String, dynamic>>? tools,
  }) async {
    final ollamaMessages = messages.map(_convertMessage).toList();
    final response = await _client.chat(
      model,
      ollamaMessages,
      options: options,
      tools: _convertTools(tools),
    );
    return ProviderChatResponse(content: response.message.content);
  }

  @override
  Stream<ProviderChatChunk> chatStream({
    required String model,
    required List<Message> messages,
    Map<String, dynamic>? options,
    List<Map<String, dynamic>>? tools,
  }) async* {
    final ollamaMessages = messages.map(_convertMessage).toList();
    await for (final response in _client.chatStream(
      model,
      ollamaMessages,
      options: options,
      tools: _convertTools(tools),
    )) {
      yield ProviderChatChunk(
        contentDelta: response.message.content,
        isDone: response.done,
      );
    }
  }

  OllamaMessage _convertMessage(Message message) {
    switch (message.role) {
      case MessageRole.user:
        List<String>? images;
        if (message.attachments.isNotEmpty) {
          images = message.attachments
              .where((a) => a.isImage)
              .map((a) => base64Encode(a.data))
              .toList();
        }
        return OllamaMessage.user(message.text, images: images);
      case MessageRole.assistant:
        return OllamaMessage.assistant(message.text);
      case MessageRole.system:
        return OllamaMessage.system(message.text);
      case MessageRole.tool:
        return OllamaMessage.tool(message.text, toolName: 'tool');
    }
  }

  List<ToolDefinition>? _convertTools(List<Map<String, dynamic>>? tools) {
    if (tools == null) return null;
    return tools.map((tool) => ToolDefinition.fromJson(tool)).toList();
  }
}

class LiteLlmProviderChatClient implements ProviderChatClient {
  final LiteLlmClient _client;

  LiteLlmProviderChatClient(this._client);

  @override
  AiProviderType get providerType => AiProviderType.liteLlm;

  @override
  Future<bool> testConnection() => _client.testConnection();

  @override
  Future<List<ProviderModelInfo>> listModels() async {
    final models = await _client.listModels();
    return models
        .map(
          (model) => ProviderModelInfo(
            name: model.id,
            capabilities: LiteLlmClient.resolveCapabilitiesFromModelId(
              model.id,
            ),
          ),
        )
        .toList();
  }

  @override
  Future<ProviderChatResponse> chat({
    required String model,
    required List<Message> messages,
    Map<String, dynamic>? options,
    List<Map<String, dynamic>>? tools,
  }) async {
    final liteMessages = messages
        .map(LiteLlmClient.buildLiteLlmMessage)
        .toList();
    final response = await _client.chat(
      model: model,
      messages: liteMessages,
      options: options,
      tools: tools,
    );
    return ProviderChatResponse(
      content: response.content,
      toolCalls: response.toolCalls,
    );
  }

  @override
  Stream<ProviderChatChunk> chatStream({
    required String model,
    required List<Message> messages,
    Map<String, dynamic>? options,
    List<Map<String, dynamic>>? tools,
  }) async* {
    final liteMessages = messages
        .map(LiteLlmClient.buildLiteLlmMessage)
        .toList();
    await for (final chunk in _client.chatStream(
      model: model,
      messages: liteMessages,
      options: options,
      tools: tools,
    )) {
      yield ProviderChatChunk(
        contentDelta: chunk.contentDelta,
        isDone: chunk.isDone,
        toolCalls: chunk.toolCalls,
      );
    }
  }
}
