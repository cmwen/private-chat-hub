import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:private_chat_hub/domain/repositories/i_chat_provider.dart';
import 'package:private_chat_hub/core/utils/logger.dart';

class OpenAIApiClient implements ChatProvider {
  final String baseUrl;
  final String apiKey;
  final String model;
  final double temperature;
  final int maxTokens;

  http.Client? _client;

  OpenAIApiClient({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.temperature = 0.7,
    this.maxTokens = 2000,
  });

  @override
  Stream<String> streamChat({
    required String model,
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
  }) async* {
    _client = http.Client();

    try {
      final endpoint = baseUrl.endsWith('/')
          ? '${baseUrl}chat/completions'
          : '$baseUrl/chat/completions';

      final messagesPayload = <Map<String, dynamic>>[];

      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        messagesPayload.add({'role': 'system', 'content': systemPrompt});
      }

      messagesPayload.addAll(messages);

      final requestBody = jsonEncode({
        'model': model.isEmpty ? this.model : model,
        'messages': messagesPayload,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'stream': true,
      });

      final request = http.Request('POST', Uri.parse(endpoint));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      });
      request.body = requestBody;

      final streamedResponse = await _client!.send(request);

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception(
          'OpenAI API error (${streamedResponse.statusCode}): $errorBody',
        );
      }

      await for (final chunk
          in streamedResponse.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (chunk.isEmpty || chunk == 'data: [DONE]') continue;

        if (chunk.startsWith('data: ')) {
          final jsonStr = chunk.substring(6);

          try {
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;
            final choices = data['choices'] as List?;

            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;

              if (content != null && content.isNotEmpty) {
                yield content;
              }
            }
          } catch (e) {
            AppLogger.error('Error parsing SSE chunk', e);
            continue;
          }
        }
      }
    } catch (e) {
      AppLogger.error('OpenAI streaming error', e);
      rethrow;
    } finally {
      _client?.close();
      _client = null;
    }
  }

  @override
  Future<void> dispose() async {
    _client?.close();
    _client = null;
  }

  @override
  String get providerName => 'OpenAI';
}
