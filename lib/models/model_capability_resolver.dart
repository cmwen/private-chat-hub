import 'package:private_chat_hub/models/on_device_model_capabilities.dart';
import 'package:private_chat_hub/ollama_toolkit/models/ollama_model.dart';

/// Resolves model capabilities from the appropriate registry (remote vs local).
class ModelCapabilityResolver {
  ModelCapabilityResolver._();

  static const ModelCapabilities unknown = ModelCapabilities(
    supportsToolCalling: false,
    supportsVision: false,
    supportsAudio: false,
    supportsThinking: false,
    contextWindow: 4096,
    description: 'Unknown model',
  );

  static ModelCapabilities? getCapabilities(String modelName) {
    if (_isLocalModel(modelName)) {
      return OnDeviceModelCapabilitiesRegistry.getCapabilities(modelName);
    }
    return ModelRegistry.getCapabilities(modelName);
  }

  static ModelCapabilities getCapabilitiesOrUnknown(String modelName) {
    return getCapabilities(modelName) ?? unknown;
  }

  static bool supportsVision(String modelName) {
    return getCapabilities(modelName)?.supportsVision ?? false;
  }

  static bool supportsAudio(String modelName) {
    return getCapabilities(modelName)?.supportsAudio ?? false;
  }

  static bool supportsToolCalling(String modelName) {
    return getCapabilities(modelName)?.supportsToolCalling ?? false;
  }

  static bool _isLocalModel(String modelName) {
    return modelName.trim().toLowerCase().startsWith('local:');
  }
}
