import 'dart:async';
import 'package:flutter/services.dart';
import 'package:private_chat_hub/domain/repositories/i_chat_provider.dart';
import 'package:private_chat_hub/core/utils/logger.dart';

class LiteRTApiClient implements ChatProvider {
  final String modelPath;
  final int maxTokens;
  final double temperature;
  final int topK;

  static const MethodChannel _channel = MethodChannel(
    'com.cmwen.private_chat_hub/litert',
  );

  bool _isInitialized = false;
  bool _isDisposed = false;

  LiteRTApiClient({
    required this.modelPath,
    this.maxTokens = 512,
    this.temperature = 0.7,
    this.topK = 40,
  });

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final result = await _channel.invokeMethod('initializeModel', {
        'modelPath': modelPath,
        'maxTokens': maxTokens,
        'temperature': temperature,
        'topK': topK,
      });

      if (result == true) {
        _isInitialized = true;
        AppLogger.info('LiteRT model initialized: $modelPath');
      } else {
        throw Exception('Failed to initialize LiteRT model');
      }
    } on PlatformException catch (e) {
      AppLogger.error('Failed to initialize LiteRT model', e);
      rethrow;
    }
  }

  @override
  Stream<String> streamChat({
    required String model,
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
  }) async* {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isDisposed) {
      throw Exception('LiteRT client has been disposed');
    }

    try {
      final prompt = _buildPrompt(messages, systemPrompt);

      final StreamController<String> controller = StreamController<String>();

      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onToken') {
          final token = call.arguments as String;
          controller.add(token);
        } else if (call.method == 'onComplete') {
          await controller.close();
        } else if (call.method == 'onError') {
          final error = call.arguments as String;
          controller.addError(Exception(error));
          await controller.close();
        }
      });

      _channel.invokeMethod('generateText', {'prompt': prompt});

      yield* controller.stream;
    } catch (e) {
      AppLogger.error('LiteRT streaming error', e);
      rethrow;
    }
  }

  String _buildPrompt(
    List<Map<String, dynamic>> messages,
    String? systemPrompt,
  ) {
    final buffer = StringBuffer();

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      buffer.writeln('System: $systemPrompt\n');
    }

    for (final message in messages) {
      final role = message['role'] ?? 'user';
      final content = message['content'] ?? '';

      if (role == 'user') {
        buffer.writeln('User: $content');
      } else if (role == 'assistant') {
        buffer.writeln('Assistant: $content');
      }
    }

    buffer.write('Assistant: ');

    return buffer.toString();
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;

    try {
      await _channel.invokeMethod('disposeModel');
      _isDisposed = true;
      _isInitialized = false;
      _channel.setMethodCallHandler(null);
      AppLogger.info('LiteRT model disposed');
    } on PlatformException catch (e) {
      AppLogger.error('Failed to dispose LiteRT model', e);
    }
  }

  @override
  String get providerName => 'LiteRT';
}
