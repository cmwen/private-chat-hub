import 'package:private_chat_hub/ollama_toolkit/ollama_toolkit.dart';
import 'package:private_chat_hub/services/llm_service.dart';
import 'package:private_chat_hub/services/on_device_llm_service.dart';

/// Service that provides a unified list of available models from both
/// Ollama (remote) and on-device (LiteRT) sources.
class UnifiedModelService {
  final OnDeviceLLMService? _onDeviceLLMService;

  UnifiedModelService({OnDeviceLLMService? onDeviceLLMService})
    : _onDeviceLLMService = onDeviceLLMService;

  /// Prefix for local model names to avoid conflicts with Ollama models
  static const String localModelPrefix = 'local:';

  /// Get a unified list of models from both Ollama and on-device sources
  Future<List<ModelInfo>> getUnifiedModelList(
    List<OllamaModelInfo> ollamaModels,
  ) async {
    final List<ModelInfo> unifiedList = [];

    // Add Ollama models (remote)
    for (final OllamaModelInfo ollamaModel in ollamaModels) {
      unifiedList.add(
        ModelInfo(
          id: ollamaModel.name,
          name: ollamaModel.name,
          description: 'Ollama model',
          sizeBytes: ollamaModel.size,
          isDownloaded: true, // Ollama models are already downloaded
          capabilities: _getOllamaCapabilities(ollamaModel),
          isLocal: false,
        ),
      );
    }

    // Add on-device models (local)
    if (_onDeviceLLMService != null) {
      try {
        final localModels = await _onDeviceLLMService.modelManager
            .getDownloadedModels();

        for (final localModel in localModels) {
          unifiedList.add(
            ModelInfo(
              id: '$localModelPrefix${localModel.id}',
              name: localModel.name,
              description: localModel.description,
              sizeBytes: localModel.sizeBytes,
              isDownloaded: localModel.isDownloaded,
              capabilities: localModel.capabilities,
              isLocal: true,
            ),
          );
        }
      } catch (e) {
        // Failed to get local models - that's OK
        print('[UnifiedModelService] Failed to get local models: $e');
      }
    }

    return unifiedList;
  }

  /// Extract capabilities from OllamaModelInfo
  List<String> _getOllamaCapabilities(OllamaModelInfo model) {
    final caps = <String>[];
    final capabilities = model.capabilities;

    if (capabilities != null) {
      if (capabilities.supportsVision) {
        caps.add('vision');
      }
      if (capabilities.supportsTools) {
        caps.add('tools');
      }
    }

    return caps;
  }

  /// Check if a model name is a local model
  static bool isLocalModel(String modelName) {
    return modelName.startsWith(localModelPrefix);
  }

  /// Get the actual model ID without the local prefix
  static String getLocalModelId(String modelName) {
    if (isLocalModel(modelName)) {
      return modelName.substring(localModelPrefix.length);
    }
    return modelName;
  }

  /// Get display name for model (without prefix)
  static String getDisplayName(String modelName) {
    if (isLocalModel(modelName)) {
      return getLocalModelId(modelName);
    }
    return modelName;
  }
}
