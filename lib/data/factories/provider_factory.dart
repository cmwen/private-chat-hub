import 'dart:convert';
import 'package:private_chat_hub/domain/entities/conversation.dart';
import 'package:private_chat_hub/domain/repositories/i_chat_provider.dart';
import 'package:private_chat_hub/data/datasources/remote/ollama_api_client.dart';
import 'package:private_chat_hub/data/datasources/remote/litert_api_client.dart';
import 'package:private_chat_hub/data/datasources/remote/openai_api_client.dart';

class ProviderFactory {
  static Future<ChatProvider> createFromConversation(
    Conversation conversation,
    String fallbackOllamaHost,
  ) async {
    switch (conversation.providerType) {
      case ProviderType.ollama:
        final config = _parseOllamaConfig(
          conversation.providerConfig,
          fallbackOllamaHost,
        );
        return OllamaApiClient(baseUrl: config['baseUrl'] as String);

      case ProviderType.litert:
        final config = _parseLiteRTConfig(conversation.providerConfig);
        final client = LiteRTApiClient(
          modelPath: config['modelPath'] as String,
          maxTokens: config['maxTokens'] as int? ?? 512,
          temperature: config['temperature'] as double? ?? 0.7,
          topK: config['topK'] as int? ?? 40,
        );
        await client.initialize();
        return client;

      case ProviderType.openai:
        final config = _parseOpenAIConfig(conversation.providerConfig);
        return OpenAIApiClient(
          baseUrl: config['baseUrl'] as String,
          apiKey: config['apiKey'] as String,
          model: config['model'] as String,
          temperature: config['temperature'] as double? ?? 0.7,
          maxTokens: config['maxTokens'] as int? ?? 2000,
        );
    }
  }

  static Map<String, dynamic> _parseOllamaConfig(
    String? configJson,
    String fallbackHost,
  ) {
    if (configJson == null || configJson.isEmpty) {
      return {'baseUrl': fallbackHost};
    }

    try {
      final config = jsonDecode(configJson) as Map<String, dynamic>;
      return {'baseUrl': config['baseUrl'] ?? fallbackHost};
    } catch (e) {
      return {'baseUrl': fallbackHost};
    }
  }

  static Map<String, dynamic> _parseLiteRTConfig(String? configJson) {
    if (configJson == null || configJson.isEmpty) {
      throw Exception('LiteRT configuration is required');
    }

    try {
      return jsonDecode(configJson) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Invalid LiteRT configuration: $e');
    }
  }

  static Map<String, dynamic> _parseOpenAIConfig(String? configJson) {
    if (configJson == null || configJson.isEmpty) {
      throw Exception('OpenAI configuration is required');
    }

    try {
      final config = jsonDecode(configJson) as Map<String, dynamic>;

      if (!config.containsKey('baseUrl')) {
        throw Exception('OpenAI baseUrl is required');
      }
      if (!config.containsKey('apiKey')) {
        throw Exception('OpenAI apiKey is required');
      }
      if (!config.containsKey('model')) {
        throw Exception('OpenAI model is required');
      }

      return config;
    } catch (e) {
      throw Exception('Invalid OpenAI configuration: $e');
    }
  }

  static String createOllamaConfig({required String baseUrl}) {
    return jsonEncode({'baseUrl': baseUrl});
  }

  static String createLiteRTConfig({
    required String modelPath,
    int maxTokens = 512,
    double temperature = 0.7,
    int topK = 40,
  }) {
    return jsonEncode({
      'modelPath': modelPath,
      'maxTokens': maxTokens,
      'temperature': temperature,
      'topK': topK,
    });
  }

  static String createOpenAIConfig({
    required String baseUrl,
    required String apiKey,
    required String model,
    double temperature = 0.7,
    int maxTokens = 2000,
  }) {
    return jsonEncode({
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
      'temperature': temperature,
      'maxTokens': maxTokens,
    });
  }
}
