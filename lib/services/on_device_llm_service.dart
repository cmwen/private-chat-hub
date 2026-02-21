import 'dart:async';
import 'dart:convert';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/services/inference_config_service.dart';
import 'package:private_chat_hub/services/litert_platform_channel.dart';
import 'package:private_chat_hub/services/llm_service.dart';
import 'package:private_chat_hub/services/model_manager.dart';
import 'package:private_chat_hub/services/storage_service.dart';

/// On-device LLM service using LiteRT-LM
///
/// This service provides on-device inference using Google's LiteRT-LM framework.
/// It implements the [LLMService] interface for seamless integration with the
/// existing chat infrastructure.
///
/// Supports configurable model parameters including temperature, top-k, top-p,
/// max tokens, and repetition penalty via [InferenceConfigService].
class OnDeviceLLMService implements LLMService {
  final ModelManager _modelManager;
  final LiteRTPlatformChannel _platformChannel;
  final InferenceConfigService? _configService;

  String? _currentModelId;

  OnDeviceLLMService(
    StorageService storage, {
    InferenceConfigService? configService,
  }) : _modelManager = ModelManager(
         storage,
         huggingFaceToken: configService?.huggingFaceToken,
       ),
       _platformChannel = LiteRTPlatformChannel(),
       _configService = configService;

  /// Create with existing ModelManager
  OnDeviceLLMService.withManager(
    this._modelManager, {
    InferenceConfigService? configService,
  }) : _platformChannel = LiteRTPlatformChannel(),
       _configService = configService;

  @override
  String? get currentModelId => _currentModelId;

  @override
  bool isModelLoaded(String modelId) => _currentModelId == modelId;

  /// Get the model manager for downloads and lifecycle
  ModelManager get modelManager => _modelManager;

  /// Update Hugging Face token
  void updateHuggingFaceToken(String? token) {
    _modelManager.updateHuggingFaceToken(token);
    _log('Hugging Face token updated in OnDeviceLLMService');
  }

  @override
  Future<bool> isAvailable() async {
    return _platformChannel.isAvailable();
  }

  /// Get detailed readiness report (support status, reasons, warnings)
  Future<Map<String, dynamic>> getReadinessReport() async {
    return _platformChannel.getReadinessReport();
  }

  @override
  Future<List<ModelInfo>> getAvailableModels() async {
    return _modelManager.getAvailableModels();
  }

  @override
  Future<void> loadModel(String modelId) async {
    _log('Loading model: $modelId');

    final success = await _modelManager.loadModel(modelId);
    if (success) {
      _currentModelId = modelId;
    } else {
      throw Exception('Failed to load model: $modelId');
    }
  }

  @override
  Future<void> unloadModel() async {
    _log('Unloading model');
    await _modelManager.unloadModel();
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
    _log(
      'generateResponse called: modelId=$modelId, '
      'currentModelId=$_currentModelId, '
      'promptLength=${prompt.length}, '
      'historyCount=${conversationHistory?.length ?? 0}, '
      'imageCount=${attachments?.where((a) => a.isImage).length ?? 0}',
    );

    // Ensure the correct model is loaded
    if (_currentModelId != modelId) {
      _log('Requested model differs from loaded model; loading $modelId');
      await loadModel(modelId);
    }

    // Use configured parameters if config service is available, otherwise use defaults
    final effectiveTemperature = _configService?.temperature ?? temperature;
    final effectiveMaxTokens = _configService?.maxTokens ?? maxTokens ?? 512;
    final effectiveTopK = _configService?.topK ?? 40;
    final effectiveTopP = _configService?.topP ?? 0.9;
    final effectiveRepetitionPenalty = _configService?.repetitionPenalty ?? 1.0;

    // Build the full prompt with conversation history
    final fullPrompt = _buildPrompt(
      prompt: prompt,
      systemPrompt: systemPrompt,
      conversationHistory: conversationHistory,
    );

    _log('Built full prompt length=${fullPrompt.length} chars');

    _log(
      'Generating response with parameters: '
      'temperature=$effectiveTemperature, '
      'maxTokens=$effectiveMaxTokens, '
      'topK=$effectiveTopK, '
      'topP=$effectiveTopP, '
      'repetitionPenalty=$effectiveRepetitionPenalty',
    );

    // Encode image attachments as base64 strings for the platform channel.
    final imageBase64List = attachments
        ?.where((a) => a.isImage)
        .map((a) => base64Encode(a.data))
        .toList();

    try {
      // Use streaming generation for real-time response with all parameters
      var chunkCount = 0;
      final startedAt = DateTime.now();

      yield* _platformChannel
          .generateTextStream(
            prompt: fullPrompt,
            temperature: effectiveTemperature,
            maxTokens: effectiveMaxTokens,
            topK: effectiveTopK,
            topP: effectiveTopP,
            repetitionPenalty: effectiveRepetitionPenalty,
            images: imageBase64List?.isNotEmpty == true
                ? imageBase64List
                : null,
          )
          .map((chunk) {
            chunkCount++;
            if (chunkCount == 1 || chunkCount % 25 == 0) {
              _log(
                'Streaming chunk received: chunkCount=$chunkCount, chunkLength=${chunk.length}',
              );
            }
            return chunk;
          });

      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      _log(
        'generateResponse completed: chunks=$chunkCount, elapsedMs=$elapsedMs',
      );

      // Reset the auto-unload timer
      _modelManager.resetUnloadTimer();
    } catch (e) {
      _log('Generation error: $e');
      rethrow;
    }
  }

  /// Build the complete prompt with system prompt and conversation history
  String _buildPrompt({
    required String prompt,
    String? systemPrompt,
    List<Message>? conversationHistory,
  }) {
    final buffer = StringBuffer();

    // Add system prompt if provided
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      buffer.writeln('<system>');
      buffer.writeln(systemPrompt);
      buffer.writeln('</system>');
      buffer.writeln();
    }

    // Add conversation history
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      for (final message in conversationHistory) {
        if (message.isMe) {
          buffer.writeln('<user>');
          buffer.writeln(message.text);
          buffer.writeln('</user>');
        } else {
          buffer.writeln('<assistant>');
          buffer.writeln(message.text);
          buffer.writeln('</assistant>');
        }
      }
    }

    // Add the current prompt
    buffer.writeln('<user>');
    buffer.writeln(prompt);
    buffer.writeln('</user>');
    buffer.writeln('<assistant>');

    return buffer.toString();
  }

  @override
  Future<void> dispose() async {
    await unloadModel();
    _modelManager.dispose();
  }

  void _log(String message) {
    // ignore: avoid_print
    print('[OnDeviceLLMService] $message');
  }
}

/// Extension on String for easy truncation
extension StringTruncate on String {
  String take(int count) {
    if (length <= count) return this;
    return '${substring(0, count)}...';
  }
}
