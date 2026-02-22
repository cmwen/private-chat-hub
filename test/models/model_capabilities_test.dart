import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/ollama_toolkit/models/ollama_model.dart';

void main() {
  group('ModelCapabilities', () {
    test('should have correct properties', () {
      const capabilities = ModelCapabilities(
        supportsToolCalling: true,
        supportsVision: false,
        supportsAudio: true,
        supportsThinking: false,
        contextWindow: 128000,
        modelFamily: 'llama',
        description: 'Test model',
      );
      expect(capabilities.supportsVision, false);
      expect(capabilities.supportsToolCalling, true);
      expect(capabilities.supportsTools, true); // Alias
      expect(capabilities.supportsAudio, true);
      expect(capabilities.supportsThinking, false);
      expect(capabilities.contextWindow, 128000);
      expect(capabilities.contextLength, 128000); // Alias
      expect(capabilities.description, 'Test model');
      expect(capabilities.modelFamily, 'llama');
      expect(capabilities.family, 'llama'); // Alias
    });
  });

  group('ModelRegistry', () {
    test('should return capabilities for exact match', () {
      final caps = ModelRegistry.getCapabilities('llama3.3');
      expect(caps, isNotNull);
      expect(caps!.supportsToolCalling, true);
      expect(caps.supportsVision, false);
      expect(caps.modelFamily, 'llama');
    });

    test('should return capabilities for model with tag', () {
      final caps = ModelRegistry.getCapabilities('llama3.3:70b');
      expect(caps, isNotNull);
      expect(caps!.supportsToolCalling, true);
      expect(caps.modelFamily, 'llama');
    });

    test('should return capabilities for vision model', () {
      final caps = ModelRegistry.getCapabilities('gemma3');
      expect(caps, isNotNull);
      expect(caps!.supportsVision, true);
      expect(caps.modelFamily, 'gemma');
    });

    test('should return capabilities for qwen models', () {
      final caps = ModelRegistry.getCapabilities('qwen2.5-coder:7b');
      expect(caps, isNotNull);
      expect(caps!.supportsToolCalling, true);
      expect(caps.modelFamily, 'qwen');
    });

    test('should return null for unrecognized model', () {
      final caps = ModelRegistry.getCapabilities('totally-unknown-model');
      expect(caps, isNull);
    });

    test('should check vision support correctly', () {
      expect(ModelRegistry.supportsVision('llama3.2'), true);
      expect(ModelRegistry.supportsVision('gemma3'), true);
      expect(ModelRegistry.supportsVision('llama3.3'), false);
    });

    test('should check audio support correctly', () {
      expect(ModelRegistry.supportsAudio('llama3.2'), false);
      expect(ModelRegistry.supportsAudio('gemma3'), false);
    });

    test('should check tool calling support correctly', () {
      expect(ModelRegistry.supportsToolCalling('llama3.3'), true);
      expect(ModelRegistry.supportsToolCalling('qwen3'), true);
      expect(ModelRegistry.supportsToolCalling('gemma3'), false);
    });

    test('should check thinking support correctly', () {
      expect(ModelRegistry.supportsThinking('deepseek-v3'), true);
      expect(ModelRegistry.supportsThinking('qwen3'), true);
      expect(ModelRegistry.supportsThinking('llama3.3'), false);
    });

    test('should list known model names', () {
      final models = ModelRegistry.getAllModelNames();
      expect(models.isNotEmpty, true);
      expect(models.contains('llama3.3'), true);
      expect(models.contains('qwen3'), true);
    });

    test('should list model families', () {
      final families = ModelRegistry.getAllModelFamilies();
      expect(families.isNotEmpty, true);
      expect(families.contains('llama'), true);
      expect(families.contains('qwen'), true);
    });

    test('should find models with specific capability', () {
      final visionModels = ModelRegistry.findModelsByCapability(
        supportsVision: true,
      );
      expect(visionModels.contains('llama3.2'), true);
      expect(visionModels.contains('gemma3'), true);
      expect(visionModels.contains('llama3.3'), false);

      final toolModels = ModelRegistry.findModelsByCapability(
        supportsToolCalling: true,
      );
      expect(toolModels.contains('llama3.3'), true);
      expect(toolModels.contains('gemma3'), false);
    });
  });
}
