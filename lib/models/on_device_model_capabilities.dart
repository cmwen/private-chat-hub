import 'package:private_chat_hub/ollama_toolkit/models/ollama_model.dart';

/// Registry of LiteRT/on-device model capabilities.
///
/// This is intentionally separate from [ModelRegistry] to keep Ollama model
/// metadata independent from on-device model metadata.
class OnDeviceModelCapabilitiesRegistry {
  OnDeviceModelCapabilitiesRegistry._();

  static const Map<String, ModelCapabilities> _registry = {
    'gemma3-1b': ModelCapabilities(
      supportsToolCalling: true,
      supportsVision: false,
      supportsAudio: false,
      supportsThinking: false,
      contextWindow: 4096,
      modelFamily: 'gemma',
      aliases: ['gemma3-1b-it', 'gemma3-1b-int4'],
      description: 'Gemma 3 1B on-device model optimized for text generation',
      useCases: ['on-device inference', 'general chat'],
    ),
    'gemma-3n-e2b': ModelCapabilities(
      supportsToolCalling: true,
      supportsVision: true,
      supportsAudio: true,
      supportsThinking: false,
      contextWindow: 4096,
      modelFamily: 'gemma',
      aliases: [
        'gemma-3n',
        'gemma-3n-e2b-it',
        'gemma-3n-e2b-it-int4',
      ],
      description: 'Gemma 3n E2B on-device multimodal model',
      useCases: ['on-device inference', 'vision', 'audio', 'tool calling'],
    ),
    'gemma-3n-e4b': ModelCapabilities(
      supportsToolCalling: true,
      supportsVision: true,
      supportsAudio: true,
      supportsThinking: false,
      contextWindow: 4096,
      modelFamily: 'gemma',
      aliases: ['gemma-3n-e4b-it', 'gemma-3n-e4b-it-int4'],
      description: 'Gemma 3n E4B on-device multimodal model',
      useCases: ['on-device inference', 'vision', 'audio', 'tool calling'],
    ),
    'phi-4-mini': ModelCapabilities(
      supportsToolCalling: true,
      supportsVision: false,
      supportsAudio: false,
      supportsThinking: false,
      contextWindow: 4096,
      modelFamily: 'phi',
      aliases: ['phi4-mini', 'phi-4-mini-instruct'],
      description: 'Phi-4 Mini on-device model',
      useCases: ['on-device inference', 'reasoning', 'tool calling'],
    ),
    'qwen2.5-1.5b': ModelCapabilities(
      supportsToolCalling: true,
      supportsVision: false,
      supportsAudio: false,
      supportsThinking: false,
      contextWindow: 4096,
      modelFamily: 'qwen',
      aliases: ['qwen2.5-1.5b-instruct'],
      description: 'Qwen 2.5 1.5B on-device model',
      useCases: ['on-device inference', 'multilingual', 'tool calling'],
    ),
  };

  static ModelCapabilities? getCapabilities(String modelId) {
    final normalized = _normalizeModelName(modelId);
    final canonical = _canonicalizeModelName(normalized);

    if (_registry.containsKey(normalized)) {
      return _registry[normalized];
    }

    for (final entry in _registry.entries) {
      if (_canonicalizeModelName(entry.key) == canonical) {
        return entry.value;
      }
      for (final alias in entry.value.aliases) {
        if (_canonicalizeModelName(alias) == canonical) {
          return entry.value;
        }
      }
    }

    return null;
  }

  static String _normalizeModelName(String modelId) {
    var normalized = modelId.trim().toLowerCase();
    if (normalized.startsWith('local:')) {
      normalized = normalized.substring('local:'.length);
    }
    final colonIndex = normalized.indexOf(':');
    if (colonIndex != -1) {
      normalized = normalized.substring(0, colonIndex);
    }
    return normalized;
  }

  static String _canonicalizeModelName(String modelId) {
    return _normalizeModelName(modelId).replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
