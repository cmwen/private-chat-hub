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
  /// Returns a stream of tokens as they are generated
  Stream<String> generateTextStream({
    required String prompt,
    double temperature = 0.7,
    int? maxTokens,
  }) {
    final controller = StreamController<String>();

    // Start generation
    _methodChannel
        .invokeMethod<void>('startGeneration', {
          'prompt': prompt,
          'temperature': temperature,
          if (maxTokens != null) 'maxTokens': maxTokens,
        })
        .catchError((error) {
          controller.addError(error);
          controller.close();
        });

    // Listen for tokens via event channel
    final subscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is String) {
          if (event == '[DONE]') {
            controller.close();
          } else {
            controller.add(event);
          }
        } else if (event is Map && event['error'] != null) {
          controller.addError(Exception(event['error']));
          controller.close();
        }
      },
      onError: (error) {
        controller.addError(error);
        controller.close();
      },
      onDone: () {
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    // Clean up subscription when stream is closed
    controller.onCancel = () {
      subscription.cancel();
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
}
