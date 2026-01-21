import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/ollama_toolkit/models/ollama_model.dart';

class LiteLlmModelInfo {
  final String id;
  final String? ownedBy;
  final Map<String, dynamic>? raw;

  const LiteLlmModelInfo({required this.id, this.ownedBy, this.raw});

  factory LiteLlmModelInfo.fromJson(Map<String, dynamic> json) {
    return LiteLlmModelInfo(
      id: json['id'] as String,
      ownedBy: json['owned_by'] as String?,
      raw: json,
    );
  }
}

class LiteLlmChatChunk {
  final String contentDelta;
  final bool isDone;
  final List<Map<String, dynamic>>? toolCalls;

  const LiteLlmChatChunk({
    required this.contentDelta,
    required this.isDone,
    this.toolCalls,
  });
}

class LiteLlmChatResponse {
  final String content;
  final List<Map<String, dynamic>>? toolCalls;

  const LiteLlmChatResponse({required this.content, this.toolCalls});
}

class LiteLlmClient {
  final String baseUrl;
  final Duration timeout;
  final http.Client _client;
  final String? apiKey;

  LiteLlmClient({
    required this.baseUrl,
    required this.timeout,
    this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<bool> testConnection() async {
    final uri = Uri.parse('$baseUrl/models');
    final response = await _client
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 5));
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<List<LiteLlmModelInfo>> listModels() async {
    final uri = Uri.parse('$baseUrl/models');
    final response = await _client
        .get(uri, headers: _headers())
        .timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('LiteLLM models request failed: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => LiteLlmModelInfo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<LiteLlmChatResponse> chat({
    required String model,
    required List<Map<String, dynamic>> messages,
    Map<String, dynamic>? options,
    List<Map<String, dynamic>>? tools,
  }) async {
    final body = _buildChatBody(
      model: model,
      messages: messages,
      options: options,
      tools: tools,
      stream: false,
    );
    final uri = Uri.parse('$baseUrl/chat/completions');
    final response = await _client
        .post(uri, headers: _headers(), body: jsonEncode(body))
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('LiteLLM chat failed: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseChatResponse(json);
  }

  Stream<LiteLlmChatChunk> chatStream({
    required String model,
    required List<Map<String, dynamic>> messages,
    Map<String, dynamic>? options,
    List<Map<String, dynamic>>? tools,
  }) async* {
    final body = _buildChatBody(
      model: model,
      messages: messages,
      options: options,
      tools: tools,
      stream: true,
    );
    final request = http.Request('POST', Uri.parse('$baseUrl/chat/completions'))
      ..headers.addAll(_headers())
      ..body = jsonEncode(body);

    final response = await _client.send(request).timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('LiteLLM stream failed: ${response.statusCode}');
    }

    final stream = response.stream.transform(utf8.decoder);
    await for (final chunk in stream) {
      final lines = chunk.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;
        final data = trimmed.substring(5).trim();
        if (data == '[DONE]') {
          yield const LiteLlmChatChunk(contentDelta: '', isDone: true);
          return;
        }
        if (data.isEmpty) continue;
        final json = jsonDecode(data) as Map<String, dynamic>;
        final choice = (json['choices'] as List<dynamic>? ?? []).firstOrNull;
        if (choice == null) continue;
        final delta = choice['delta'] as Map<String, dynamic>? ?? {};
        final content = delta['content'] as String? ?? '';
        final toolCalls = (delta['tool_calls'] as List<dynamic>?)
            ?.map((tool) => tool as Map<String, dynamic>)
            .toList();
        yield LiteLlmChatChunk(
          contentDelta: content,
          isDone: choice['finish_reason'] != null,
          toolCalls: toolCalls,
        );
      }
    }
  }

  Map<String, String> _headers() {
    final headers = {'Content-Type': 'application/json'};
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    return headers;
  }

  Map<String, dynamic> _buildChatBody({
    required String model,
    required List<Map<String, dynamic>> messages,
    required bool stream,
    Map<String, dynamic>? options,
    List<Map<String, dynamic>>? tools,
  }) {
    return {
      'model': model,
      'messages': messages,
      if (options != null) ...options,
      if (tools != null && tools.isNotEmpty) 'tools': tools,
      'stream': stream,
    };
  }

  LiteLlmChatResponse _parseChatResponse(Map<String, dynamic> json) {
    final choices = json['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) {
      return const LiteLlmChatResponse(content: '');
    }

    final message = choices.first['message'] as Map<String, dynamic>? ?? {};
    final content = message['content'] as String? ?? '';
    final toolCalls = (message['tool_calls'] as List<dynamic>?)
        ?.map((tool) => tool as Map<String, dynamic>)
        .toList();
    return LiteLlmChatResponse(content: content, toolCalls: toolCalls);
  }

  static Map<String, dynamic> buildLiteLlmMessage(Message message) {
    switch (message.role) {
      case MessageRole.system:
        return {'role': 'system', 'content': message.text};
      case MessageRole.user:
        return _buildUserMessage(message);
      case MessageRole.assistant:
        return {'role': 'assistant', 'content': message.text};
      case MessageRole.tool:
        return {'role': 'tool', 'content': message.text};
    }
  }

  static Map<String, dynamic> _buildUserMessage(Message message) {
    if (!message.hasImages) {
      return {'role': 'user', 'content': message.text};
    }

    final parts = <Map<String, dynamic>>[
      {'type': 'text', 'text': message.text},
    ];

    for (final image in message.images) {
      final base64Data = base64Encode(image.data);
      parts.add({
        'type': 'image_url',
        'image_url': {'url': 'data:${image.mimeType};base64,$base64Data'},
      });
    }

    return {'role': 'user', 'content': parts};
  }

  static ModelCapabilities? resolveCapabilitiesFromModelId(String modelId) {
    return ModelRegistry.getCapabilities(modelId);
  }
}

extension _FirstOrNullExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
