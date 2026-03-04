import 'dart:async';
import 'dart:convert';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/models/opencode_models.dart';
import 'package:private_chat_hub/services/llm_service.dart';
import 'package:private_chat_hub/services/opencode_connection_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LLM service implementation for OpenCode server.
///
/// Communicates with an OpenCode server to access cloud LLM providers
/// (Anthropic, OpenAI, Google, etc.) through the OpenCode API.
class OpenCodeLLMService implements LLMService {
  final OpenCodeConnectionManager _connectionManager;

  String? _currentModelId;

  /// Cached providers from last fetch.
  OpenCodeProviderResponse? _cachedProviders;

  /// Maps conversation IDs to OpenCode session IDs.
  final Map<String, String> _sessionMap = {};

  static const String _sessionMapKey = 'opencode_session_map';

  OpenCodeLLMService(this._connectionManager) {
    _loadSessionMap();
  }

  @override
  String? get currentModelId => _currentModelId;

  @override
  bool isModelLoaded(String modelId) => _currentModelId == modelId;

  @override
  Future<bool> isAvailable() async {
    return _connectionManager.testConnection();
  }

  @override
  Future<List<ModelInfo>> getAvailableModels() async {
    try {
      final providers = await _connectionManager.client.getProviders();
      _cachedProviders = providers;
      return _convertToModelInfoList(providers);
    } catch (e) {
      _log('Failed to get OpenCode models: $e');
      return [];
    }
  }

  /// Get the raw provider response (for UI that needs provider grouping).
  Future<OpenCodeProviderResponse?> getProviders() async {
    try {
      final providers = await _connectionManager.client.getProviders();
      _cachedProviders = providers;
      return providers;
    } catch (e) {
      _log('Failed to get providers: $e');
      return _cachedProviders;
    }
  }

  /// Get cached providers without making an API call.
  OpenCodeProviderResponse? get cachedProviders => _cachedProviders;

  @override
  Future<void> loadModel(String modelId) async {
    _currentModelId = modelId;
    _log('Model set to: $modelId');
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

    // Strip the opencode: prefix to get providerId/modelId
    final actualModelId = _stripPrefix(modelId);

    // Build the full prompt including system prompt and history
    final fullPrompt = _buildPrompt(
      prompt: prompt,
      conversationHistory: conversationHistory,
      systemPrompt: systemPrompt,
    );

    _log('Sending message to OpenCode, model: $actualModelId');

    try {
      // For OpenCode, we use the synchronous message endpoint
      // which returns the full response at once.
      // In the future, we can use SSE for streaming.

      // Get or create session for this conversation
      final sessionId = await _getOrCreateSession();

      final response = await _connectionManager.client.sendMessage(
        sessionId,
        text: fullPrompt,
        providerModelId: actualModelId,
      );

      // Extract text content from response parts
      final text = _extractResponseText(response);
      if (text.isNotEmpty) {
        // Simulate streaming by yielding chunks
        const chunkSize = 50;
        for (var i = 0; i < text.length; i += chunkSize) {
          final end = (i + chunkSize).clamp(0, text.length);
          yield text.substring(i, end);
          // Small delay to simulate streaming
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }
    } catch (e) {
      _log('Generation error: $e');
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    _currentModelId = null;
  }

  // ── Helpers ────────────────────────────────────────────────────

  /// Strip the `opencode:` prefix from a model ID.
  String _stripPrefix(String modelId) {
    if (modelId.startsWith('opencode:')) {
      return modelId.substring('opencode:'.length);
    }
    return modelId;
  }

  /// Build a flat prompt from system prompt + history + current prompt.
  String _buildPrompt({
    required String prompt,
    List<Message>? conversationHistory,
    String? systemPrompt,
  }) {
    // For OpenCode, we send just the user's prompt.
    // The OpenCode session maintains its own conversation history.
    // System prompt is handled via session config.
    return prompt;
  }

  /// Extract text content from OpenCode message response.
  String _extractResponseText(Map<String, dynamic> response) {
    final buffer = StringBuffer();

    // Response format: { info: Message, parts: Part[] }
    final parts = response['parts'] as List<dynamic>? ?? [];
    for (final part in parts) {
      if (part is Map<String, dynamic>) {
        final type = part['type'] as String?;
        if (type == 'text') {
          final text = part['text'] as String? ?? '';
          buffer.write(text);
        }
      }
    }

    return buffer.toString();
  }

  /// Get or create an OpenCode session for the current interaction.
  Future<String> _getOrCreateSession({String? conversationId}) async {
    // Check for existing session
    final key = conversationId ?? '_default';
    if (_sessionMap.containsKey(key)) {
      return _sessionMap[key]!;
    }

    // Create a new session
    final session = await _connectionManager.client.createSession(
      title: 'Private Chat Hub',
    );
    final sessionId = session['id'] as String;
    _sessionMap[key] = sessionId;
    await _saveSessionMap();
    return sessionId;
  }

  /// Convert provider response to list of ModelInfo for unified service.
  List<ModelInfo> _convertToModelInfoList(
    OpenCodeProviderResponse providers,
  ) {
    final models = <ModelInfo>[];
    for (final entry in providers.allModels) {
      final model = entry.model;
      final providerId = entry.providerId;
      final modelId = 'opencode:$providerId/${model.modelKey}';

      models.add(
        ModelInfo(
          id: modelId,
          name: model.displayName,
          description: '${_getProviderDisplayName(providerId)} · '
              '${model.limit?.contextDisplay ?? 'Unknown'} context',
          sizeBytes: 0,
          isDownloaded: true,
          capabilities: model.capabilities,
          isLocal: false,
        ),
      );
    }
    return models;
  }

  /// Get human-readable provider name.
  String _getProviderDisplayName(String providerId) {
    switch (providerId.toLowerCase()) {
      case 'anthropic':
        return 'Anthropic';
      case 'openai':
        return 'OpenAI';
      case 'google':
        return 'Google';
      case 'mistral':
        return 'Mistral';
      case 'groq':
        return 'Groq';
      case 'deepseek':
        return 'DeepSeek';
      case 'xai':
        return 'xAI';
      case 'aws':
        return 'AWS Bedrock';
      case 'azure':
        return 'Azure';
      case 'copilot':
        return 'GitHub Copilot';
      default:
        return providerId;
    }
  }

  // ── Session map persistence ────────────────────────────────────

  Future<void> _loadSessionMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_sessionMapKey);
      if (json != null) {
        final map = Map<String, dynamic>.from(
          (await Future.value(json)).isEmpty
              ? {}
              : Map<String, dynamic>.from(
                  (json.isNotEmpty)
                      ? (Map<String, dynamic>.from(
                          _tryDecodeJson(json) ?? {},
                        ))
                      : {},
                ),
        );
        for (final entry in map.entries) {
          if (entry.value is String) {
            _sessionMap[entry.key] = entry.value as String;
          }
        }
      }
    } catch (_) {}
  }

  Map<String, dynamic>? _tryDecodeJson(String json) {
    try {
      final decoded =
          const JsonDecoder().convert(json) as Map<String, dynamic>?;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveSessionMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _sessionMapKey,
        const JsonEncoder().convert(_sessionMap),
      );
    } catch (_) {}
  }

  void _log(String message) {
    // ignore: avoid_print
    print('[OpenCodeLLMService] $message');
  }
}
