import 'dart:convert';

import 'package:private_chat_hub/ollama_toolkit/ollama_toolkit.dart';
import 'package:private_chat_hub/services/llm_service.dart';
import 'package:private_chat_hub/services/on_device_llm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that provides a unified list of available models from both
/// Ollama (remote) and on-device (LiteRT) sources.
///
/// When remote models are fetched successfully they are cached to
/// SharedPreferences so they remain visible when Ollama goes offline.
class UnifiedModelService {
  final OnDeviceLLMService? _onDeviceLLMService;

  /// SharedPreferences key for cached remote model list.
  static const String _cachedRemoteModelsKey = 'cached_remote_models';

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

  // ---------------------------------------------------------------------------
  // Remote model caching
  // ---------------------------------------------------------------------------

  /// Persist the remote (non-local) models from [allModels] to
  /// SharedPreferences so they can be shown when Ollama is offline.
  static Future<void> cacheRemoteModels(List<ModelInfo> allModels) async {
    final remoteOnly = allModels.where((m) => !m.isLocal).toList();
    final prefs = await SharedPreferences.getInstance();
    final jsonList = remoteOnly.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(_cachedRemoteModelsKey, jsonList);
  }

  /// Load previously-cached remote models.  Returns an empty list if nothing
  /// has been cached yet.
  static Future<List<ModelInfo>> getCachedRemoteModels() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_cachedRemoteModelsKey);
    if (jsonList == null || jsonList.isEmpty) return [];
    try {
      return jsonList
          .map((s) => ModelInfo.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
