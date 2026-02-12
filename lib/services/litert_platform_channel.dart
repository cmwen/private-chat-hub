import 'dart:async';
import 'package:flutter/services.dart';

/// Platform channel for communicating with LiteRT-LM native code
///
/// This class handles all communication between Flutter and the Kotlin
/// LiteRTPlugin for on-device LLM inference.
class LiteRTPlatformChannel {
  static const String _methodChannelName = 'com.cmwen.private_chat_hub/litert';
  static const String _eventChannelName =
      'com.cmwen.private_chat_hub/litert_stream';

  static const MethodChannel _methodChannel = MethodChannel(_methodChannelName);
  static const EventChannel _eventChannel = EventChannel(_eventChannelName);

  static final LiteRTPlatformChannel _instance =
      LiteRTPlatformChannel._internal();

  factory LiteRTPlatformChannel() => _instance;

  LiteRTPlatformChannel._internal();

  /// Load a model from the given path
  ///
  /// [modelPath] - Full path to the .litertlm model file
  /// [backend] - Backend to use: 'cpu', 'gpu', or 'npu'
  ///
  /// Returns true if model was loaded successfully
  Future<bool> loadModel({
    required String modelPath,
    String backend = 'gpu',
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('loadModel', {
        'modelPath': modelPath,
        'backend': backend,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      _log('Failed to load model: ${e.message}');
      return false;
    } on MissingPluginException catch (e) {
      _log('LiteRT plugin not available: ${e.message}');
      return false;
    }
  }

  /// Unload the currently loaded model to free memory
  ///
  /// Returns true if model was unloaded successfully
  Future<bool> unloadModel() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('unloadModel');
      return result ?? false;
    } on PlatformException catch (e) {
      _log('Failed to unload model: ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Generate text from a prompt (synchronous/blocking)
  ///
  /// [prompt] - The input prompt to generate from
  /// [temperature] - Sampling temperature (0.0 to 1.0)
  /// [maxTokens] - Maximum tokens to generate
  ///
  /// Returns the generated text
  Future<String> generateText({
    required String prompt,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<String>('generateText', {
        'prompt': prompt,
        'temperature': temperature,
        if (maxTokens != null) 'maxTokens': maxTokens,
      });
      return result ?? '';
    } on PlatformException catch (e) {
      _log('Failed to generate text: ${e.message}');
      rethrow;
    } on MissingPluginException catch (e) {
      _log('LiteRT plugin not available: ${e.message}');
      rethrow;
    }
  }

  /// Generate text with streaming (token-by-token)
  ///
  /// Returns a stream of tokens as they are generated.
  /// Supports configurable model parameters:
  /// - [temperature]: Controls randomness (0.0-2.0, default 0.7)
  /// - [topK]: Only consider top K tokens (default 40)
  /// - [topP]: Nucleus sampling parameter (0.0-1.0, default 0.9)
  /// - [maxTokens]: Maximum tokens to generate
  /// - [repetitionPenalty]: Penalize repeated tokens (0.5-2.0, default 1.0)
  Stream<String> generateTextStream({
    required String prompt,
    double temperature = 0.7,
    int? maxTokens,
    int topK = 40,
    double topP = 0.9,
    double repetitionPenalty = 1.0,
  }) {
    final controller = StreamController<String>();
    StreamSubscription? subscription;

    Future<void> closeController() async {
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    controller.onListen = () {
      // Listen for events first to avoid missing early tokens.
      subscription = _eventChannel.receiveBroadcastStream().listen(
        (event) {
          if (event is String) {
            if (event == '[DONE]') {
              closeController();
            } else if (event.isNotEmpty) {
              controller.add(event);
            }
            return;
          }

          if (event is Map) {
            final error = event['error'];
            if (error != null) {
              controller.addError(Exception(error.toString()));
              closeController();
              return;
            }

            final token =
                event['token'] ??
                event['text'] ??
                event['content'] ??
                event['delta'];
            if (token is String && token.isNotEmpty) {
              controller.add(token);
            }

            final isDone =
                event['done'] == true ||
                event['isDone'] == true ||
                event['type'] == 'done';
            if (isDone) {
              closeController();
            }
          }
        },
        onError: (error) {
          controller.addError(error);
          closeController();
        },
        onDone: () {
          closeController();
        },
      );

      // Start generation after event subscription is attached.
      _methodChannel
          .invokeMethod<void>('startGeneration', {
            'prompt': prompt,
            'temperature': temperature,
            if (maxTokens != null) 'maxTokens': maxTokens,
            'topK': topK,
            'topP': topP,
            'repetitionPenalty': repetitionPenalty,
          })
          .catchError((error) {
            controller.addError(error);
            closeController();
          });
    };

    // Clean up subscription when stream is closed/cancelled
    controller.onCancel = () {
      subscription?.cancel();
      _methodChannel.invokeMethod<void>('cancelGeneration');
    };

    return controller.stream;
  }

  /// Stop any ongoing generation
  Future<void> cancelGeneration() async {
    try {
      await _methodChannel.invokeMethod<void>('cancelGeneration');
    } on PlatformException catch (e) {
      _log('Failed to cancel generation: ${e.message}');
    } on MissingPluginException {
      // Ignore if plugin not available
    }
  }

  /// Check if a model is currently loaded
  Future<bool> isModelLoaded() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isModelLoaded');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Get the ID of the currently loaded model
  Future<String?> getCurrentModelId() async {
    try {
      return await _methodChannel.invokeMethod<String>('getCurrentModelId');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Check if LiteRT-LM is available on this device
  Future<bool> isAvailable() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Get on-device inference readiness report with capability details
  Future<Map<String, dynamic>> getReadinessReport() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getReadinessReport',
      );

      if (result == null) {
        return _defaultReadinessReport();
      }

      return {
        'isSupported': result['isSupported'] as bool? ?? false,
        'androidApi': result['androidApi'] as int? ?? 0,
        'androidVersion': result['androidVersion'] as String? ?? 'unknown',
        'deviceModel': result['deviceModel'] as String? ?? 'unknown',
        'cpu': result['cpu'] as bool? ?? true,
        'gpu': result['gpu'] as bool? ?? false,
        'npu': result['npu'] as bool? ?? false,
        'has64BitAbi': result['has64BitAbi'] as bool? ?? false,
        'supported64BitAbis':
            (result['supported64BitAbis'] as List?)?.cast<String>() ??
            <String>[],
        'totalMemory': result['totalMemory'] as int? ?? 0,
        'availableMemory': result['availableMemory'] as int? ?? 0,
        'unsupportedReasons':
            (result['unsupportedReasons'] as List?)?.cast<String>() ??
            <String>[],
        'warnings': (result['warnings'] as List?)?.cast<String>() ?? <String>[],
      };
    } on PlatformException {
      return _defaultReadinessReport();
    } on MissingPluginException {
      return _defaultReadinessReport();
    }
  }

  /// Get device capabilities (CPU, GPU, NPU support)
  Future<Map<String, bool>> getDeviceCapabilities() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getDeviceCapabilities',
      );
      if (result == null) {
        return {'cpu': true, 'gpu': false, 'npu': false};
      }
      return {
        'cpu': result['cpu'] as bool? ?? true,
        'gpu': result['gpu'] as bool? ?? false,
        'npu': result['npu'] as bool? ?? false,
      };
    } on PlatformException {
      return {'cpu': true, 'gpu': false, 'npu': false};
    } on MissingPluginException {
      return {'cpu': true, 'gpu': false, 'npu': false};
    }
  }

  /// Get memory usage information
  Future<Map<String, int>> getMemoryInfo() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getMemoryInfo',
      );
      if (result == null) {
        return {};
      }
      return {
        'totalMemory': result['totalMemory'] as int? ?? 0,
        'availableMemory': result['availableMemory'] as int? ?? 0,
        'modelMemory': result['modelMemory'] as int? ?? 0,
      };
    } on PlatformException {
      return {};
    } on MissingPluginException {
      return {};
    }
  }

  /// Get benchmark results for the loaded model
  Future<Map<String, double>> getBenchmark() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getBenchmark',
      );
      if (result == null) {
        return {};
      }
      return {
        'prefillTokensPerSec':
            (result['prefillTokensPerSec'] as num?)?.toDouble() ?? 0,
        'decodeTokensPerSec':
            (result['decodeTokensPerSec'] as num?)?.toDouble() ?? 0,
        'loadTimeMs': (result['loadTimeMs'] as num?)?.toDouble() ?? 0,
      };
    } on PlatformException {
      return {};
    } on MissingPluginException {
      return {};
    }
  }

  void _log(String message) {
    // ignore: avoid_print
    print('[LiteRTPlatformChannel] $message');
  }

  Map<String, dynamic> _defaultReadinessReport() {
    return {
      'isSupported': false,
      'androidApi': 0,
      'androidVersion': 'unknown',
      'deviceModel': 'unknown',
      'cpu': true,
      'gpu': false,
      'npu': false,
      'has64BitAbi': false,
      'supported64BitAbis': <String>[],
      'totalMemory': 0,
      'availableMemory': 0,
      'unsupportedReasons': <String>['LiteRT plugin unavailable'],
      'warnings': <String>[],
    };
  }
}
