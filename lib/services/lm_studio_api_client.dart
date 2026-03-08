import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:private_chat_hub/models/lm_studio_connection.dart';
import 'package:private_chat_hub/models/lm_studio_models.dart';
import 'package:private_chat_hub/models/message.dart';

/// Low-level HTTP client for the LM Studio REST API.
class LmStudioApiClient {
  LmStudioConnection? _connection;
  http.Client? _httpClient;

  Duration timeout = const Duration(seconds: 30);

  void setConnection(LmStudioConnection connection) {
    _connection = connection;
    _httpClient?.close();
    _httpClient = http.Client();
  }

  void clearConnection() {
    _connection = null;
    _httpClient?.close();
    _httpClient = null;
  }

  LmStudioConnection? get connection => _connection;

  String? get baseUrl => _connection?.url;

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_connection?.hasApiToken == true) {
      headers['Authorization'] = 'Bearer ${_connection!.apiToken!}';
    }
    return headers;
  }

  Future<bool> checkHealth() async {
    try {
      await listModels();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<LmStudioModelsResponse> listModels() async {
    final response = await _get('/api/v1/models');
    if (response.statusCode != 200) {
      throw LmStudioApiException(
        'Failed to list models',
        response.statusCode,
        response.body,
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return LmStudioModelsResponse.fromJson(body);
  }

  Future<LmStudioChatResult> chat({
    required String modelId,
    required String prompt,
    List<Attachment>? attachments,
    String? systemPrompt,
    double temperature = 0.7,
    int? maxTokens,
    String? previousResponseId,
  }) async {
    final response = await _post(
      '/api/v1/chat',
      body: _buildChatBody(
        modelId: modelId,
        prompt: prompt,
        attachments: attachments,
        systemPrompt: systemPrompt,
        stream: false,
        temperature: temperature,
        maxTokens: maxTokens,
        previousResponseId: previousResponseId,
      ),
      longTimeout: true,
    );

    if (response.statusCode != 200) {
      throw LmStudioApiException(
        'Failed to generate chat response',
        response.statusCode,
        response.body,
      );
    }

    return LmStudioChatResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Stream<LmStudioChatStreamEvent> chatStream({
    required String modelId,
    required String prompt,
    List<Attachment>? attachments,
    String? systemPrompt,
    double temperature = 0.7,
    int? maxTokens,
    String? previousResponseId,
  }) async* {
    _ensureConnection();

    final request = http.Request(
      'POST',
      Uri.parse('${baseUrl!}/api/v1/chat'),
    );
    request.headers.addAll({
      ..._headers,
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    });
    request.body = jsonEncode(
      _buildChatBody(
        modelId: modelId,
        prompt: prompt,
        attachments: attachments,
        systemPrompt: systemPrompt,
        stream: true,
        temperature: temperature,
        maxTokens: maxTokens,
        previousResponseId: previousResponseId,
      ),
    );

    final client = http.Client();
    try {
      final response = await client.send(request).timeout(const Duration(minutes: 5));
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw LmStudioApiException(
          'Failed to open chat stream',
          response.statusCode,
          body,
        );
      }

      String currentEvent = 'message';
      final dataBuffer = StringBuffer();

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.isEmpty) {
          if (dataBuffer.isNotEmpty) {
            final rawData = dataBuffer.toString().trim();
            dataBuffer.clear();
            try {
              final payload = jsonDecode(rawData) as Map<String, dynamic>;
              yield LmStudioChatStreamEvent(type: currentEvent, data: payload);
            } catch (_) {
              // Ignore malformed event data.
            }
          }
          currentEvent = 'message';
          continue;
        }

        if (line.startsWith('event:')) {
          currentEvent = line.substring(6).trim();
          continue;
        }

        if (line.startsWith('data:')) {
          dataBuffer.writeln(line.substring(5).trim());
        }
      }

      if (dataBuffer.isNotEmpty) {
        try {
          final payload = jsonDecode(dataBuffer.toString()) as Map<String, dynamic>;
          yield LmStudioChatStreamEvent(type: currentEvent, data: payload);
        } catch (_) {}
      }
    } finally {
      client.close();
    }
  }

  Map<String, dynamic> _buildChatBody({
    required String modelId,
    required String prompt,
    required bool stream,
    List<Attachment>? attachments,
    String? systemPrompt,
    double temperature = 0.7,
    int? maxTokens,
    String? previousResponseId,
  }) {
    final body = <String, dynamic>{
      'model': modelId,
      'input': _buildInput(prompt, attachments: attachments),
      'stream': stream,
      'temperature': temperature.clamp(0.0, 1.0),
      'store': false,
    };

    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      body['system_prompt'] = systemPrompt;
    }
    if (maxTokens != null) {
      body['max_output_tokens'] = maxTokens;
    }
    if (previousResponseId != null && previousResponseId.isNotEmpty) {
      body['previous_response_id'] = previousResponseId;
    }

    return body;
  }

  Object _buildInput(String prompt, {List<Attachment>? attachments}) {
    final imageAttachments = (attachments ?? const <Attachment>[])
        .where((attachment) => attachment.isImage)
        .toList();

    if (imageAttachments.isEmpty) {
      return prompt;
    }

    return [
      {'type': 'message', 'content': prompt},
      ...imageAttachments.map(
        (attachment) => {
          'type': 'image',
          'data_url':
              'data:${attachment.mimeType};base64,${base64Encode(attachment.data)}',
        },
      ),
    ];
  }

  Future<http.Response> _get(String path) async {
    _ensureConnection();
    return _httpClient!
        .get(Uri.parse('${baseUrl!}$path'), headers: _headers)
        .timeout(timeout);
  }

  Future<http.Response> _post(
    String path, {
    required Map<String, dynamic> body,
    bool longTimeout = false,
  }) async {
    _ensureConnection();
    return _httpClient!
        .post(
          Uri.parse('${baseUrl!}$path'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(longTimeout ? const Duration(minutes: 5) : timeout);
  }

  void _ensureConnection() {
    if (_connection == null || _httpClient == null) {
      throw const LmStudioApiException('No connection configured', 0);
    }
  }

  void dispose() {
    _httpClient?.close();
    _httpClient = null;
  }
}

class LmStudioApiException implements Exception {
  final String message;
  final int statusCode;
  final String? responseBody;

  const LmStudioApiException(this.message, this.statusCode, [this.responseBody]);

  @override
  String toString() {
    if (responseBody == null || responseBody!.trim().isEmpty) {
      return 'LmStudioApiException($statusCode): $message';
    }
    return 'LmStudioApiException($statusCode): $message - $responseBody';
  }
}