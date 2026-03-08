import 'dart:convert';

import 'package:private_chat_hub/ollama_toolkit/ollama_toolkit.dart';
import 'package:private_chat_hub/services/llm_service.dart';
import 'package:private_chat_hub/services/on_device_llm_service.dart';
import 'package:private_chat_hub/services/opencode_llm_service.dart';
import 'package:private_chat_hub/services/opencode_model_visibility_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that provides a unified list of available models from both
/// Ollama (remote) and on-device (LiteRT) sources.
///
/// When remote models are fetched successfully they are cached to
/// SharedPreferences so they remain visible when Ollama goes offline.
class UnifiedModelService {
  final OnDeviceLLMService? _onDeviceLLMService;
  final OpenCodeLLMService? _openCodeLLMService;
  final OpenCodeModelVisibilityService? _visibilityService;

  /// SharedPreferences key for cached remote model list.
  static const String _cachedRemoteModelsKey = 'cached_remote_models';

  UnifiedModelService({
    OnDeviceLLMService? onDeviceLLMService,
    OpenCodeLLMService? openCodeLLMService,
    OpenCodeModelVisibilityService? visibilityService,
  }) : _onDeviceLLMService = onDeviceLLMService,
       _openCodeLLMService = openCodeLLMService,
       _visibilityService = visibilityService;

  /// Prefix for local model names to avoid conflicts with Ollama models
  static const String localModelPrefix = 'local:';

  /// Prefix for OpenCode model names
  static const String openCodeModelPrefix = 'opencode:';

  /// Get a unified list of models from both Ollama and on-device sources
  Future<List<ModelInfo>> getUnifiedModelList(
    List<OllamaModelInfo> ollamaModels,
  ) async {
    // Fetch local and OpenCode models in parallel for faster loading.
    // Each future resolves to a List<ModelInfo>; destructuring preserves
    // the explicit relationship between the fetch order and the result names.
    final [localModels, openCodeModels] = await Future.wait<List<ModelInfo>>([
      // On-device local models
      () async {
        if (_onDeviceLLMService == null) return <ModelInfo>[];
        try {
          final downloaded =
              await _onDeviceLLMService.modelManager.getDownloadedModels();
          return downloaded
              .map(
                (localModel) {
                  final modelId = '$localModelPrefix${localModel.id}';
                  if (_visibilityService != null &&
                      !_visibilityService.isModelVisible(modelId)) {
                    return null;
                  }
                  return ModelInfo(
                    id: modelId,
                    name: localModel.name,
                    description: localModel.description,
                    sizeBytes: localModel.sizeBytes,
                    isDownloaded: localModel.isDownloaded,
                    capabilities: localModel.capabilities,
                    isLocal: true,
                  );
                },
              )
              .whereType<ModelInfo>()
              .toList();
        } catch (e) {
          print('[UnifiedModelService] Failed to get local models: $e');
          return <ModelInfo>[];
        }
      }(),
      // OpenCode cloud models
      () async {
        if (_openCodeLLMService == null) return <ModelInfo>[];
        try {
          final openCodeModels =
              await _openCodeLLMService.getAvailableModels();
          return openCodeModels.where((model) {
            if (_visibilityService != null &&
                !_visibilityService.isModelVisible(model.id)) {
              return false;
            }
            return true;
          }).toList();
        } catch (e) {
          print('[UnifiedModelService] Failed to get OpenCode models: $e');
          return <ModelInfo>[];
        }
      }(),
    ]);

    final List<ModelInfo> unifiedList = [];

    // Add Ollama models first (remote, highest priority)
    for (final OllamaModelInfo ollamaModel in ollamaModels) {
      if (_visibilityService != null &&
          !_visibilityService.isModelVisible(ollamaModel.name)) {
        continue;
      }

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

    unifiedList.addAll(localModels);
    unifiedList.addAll(openCodeModels);

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

  /// Check if a model name is an OpenCode model
  static bool isOpenCodeModel(String modelName) {
    return modelName.startsWith(openCodeModelPrefix);
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
    if (isOpenCodeModel(modelName)) {
      // Show provider/model without the opencode: prefix
      return modelName.substring(openCodeModelPrefix.length);
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
