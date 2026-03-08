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
    if (_isLmStudioModel(modelName)) {
      return _getLmStudioCapabilities(modelName);
    }
    if (_isOpenCodeModel(modelName)) {
      return _getOpenCodeCapabilities(modelName);
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

  static bool _isOpenCodeModel(String modelName) {
    return modelName.trim().toLowerCase().startsWith('opencode:');
  }

  static bool _isLmStudioModel(String modelName) {
    return modelName.trim().toLowerCase().startsWith('lmstudio:');
  }

  static ModelCapabilities _getLmStudioCapabilities(String modelName) {
    final normalized = modelName.substring('lmstudio:'.length).toLowerCase();
    final supportsVision =
        normalized.contains('vision') ||
        normalized.contains('llava') ||
        normalized.contains('minicpm-v');
    final supportsTools =
        normalized.contains('tool') ||
        normalized.contains('function') ||
        normalized.contains('qwen') ||
        normalized.contains('llama-3.1') ||
        normalized.contains('llama3.1');

    return ModelCapabilities(
      supportsToolCalling: supportsTools,
      supportsVision: supportsVision,
      supportsAudio: false,
      supportsThinking: false,
      contextWindow: 32768,
      description: 'LM Studio model',
    );
  }

  /// Returns capabilities for an OpenCode cloud model based on known
  /// provider defaults.  Vision and thinking are inferred from the model
  /// name; tool-calling is enabled for most modern cloud providers.
  static ModelCapabilities _getOpenCodeCapabilities(String modelName) {
    // Strip the 'opencode:' prefix and split into provider/model.
    final withoutPrefix = modelName.substring('opencode:'.length);
    final slashIndex = withoutPrefix.indexOf('/');
    final provider =
        (slashIndex > 0
                ? withoutPrefix.substring(0, slashIndex)
                : withoutPrefix)
            .toLowerCase();
    final modelPart = slashIndex > 0
        ? withoutPrefix.substring(slashIndex + 1).toLowerCase()
        : '';

    bool supportsTools = true; // most cloud providers support tool calling
    bool supportsVision = false;
    bool supportsThinking = false;

    switch (provider) {
      case 'anthropic':
        // Claude 3+ series supports vision; claude-3-7 adds extended thinking.
        supportsVision = true;
        supportsThinking =
            modelPart.contains('claude-3-7') ||
            modelPart.contains('claude-3.7');
      case 'openai':
        supportsVision =
            modelPart.contains('4o') ||
            modelPart.contains('4-vision') ||
            modelPart.contains('gpt-4v');
        supportsThinking = modelPart.contains('o1') || modelPart.contains('o3');
      case 'google':
        // Gemini 1.5+ and 2.0+ support vision; flash-thinking has reasoning.
        supportsVision = true;
        supportsThinking =
            modelPart.contains('think') || modelPart.contains('flash-2');
      case 'copilot':
      case 'github-copilot':
      case 'github-copilot-models':
        supportsVision =
            modelPart.contains('4o') ||
            modelPart.contains('claude') ||
            modelPart.contains('vision');
        supportsThinking = modelPart.contains('o1') || modelPart.contains('o3');
      case 'groq':
        supportsVision = modelPart.contains('vision');
      case 'mistral':
        supportsVision =
            modelPart.contains('pixtral') ||
            modelPart.contains('vision') ||
            modelPart.contains('ministral');
      case 'deepseek':
        supportsThinking =
            modelPart.contains('reasoner') || modelPart.contains('r1');
      default:
        // For unknown providers, enable tools but be conservative about vision.
        supportsVision = modelPart.contains('vision');
    }

    return ModelCapabilities(
      supportsToolCalling: supportsTools,
      supportsVision: supportsVision,
      supportsAudio: false,
      supportsThinking: supportsThinking,
      contextWindow: 128000,
      description: 'OpenCode cloud model ($provider)',
    );
  }
}
