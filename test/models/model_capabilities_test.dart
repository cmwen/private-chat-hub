import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/model_capabilities.dart';

void main() {
  group('ModelCapabilities', () {
    test('should have correct default values', () {
      const capabilities = ModelCapabilities();
      expect(capabilities.supportsVision, false);
      expect(capabilities.supportsTools, false);
      expect(capabilities.supportsCode, false);
      expect(capabilities.contextLength, 4096);
      expect(capabilities.description, '');
      expect(capabilities.family, 'unknown');
    });

    test('unknown should have default capabilities', () {
      expect(ModelCapabilities.unknown.supportsVision, false);
      expect(ModelCapabilities.unknown.supportsTools, false);
      expect(ModelCapabilities.unknown.supportsCode, false);
      expect(ModelCapabilities.unknown.family, 'unknown');
    });
  });

  group('ModelCapabilitiesRegistry', () {
    test('should return capabilities for exact match', () {
      final caps = ModelCapabilitiesRegistry.getCapabilities('llama3.3');
      expect(caps.supportsTools, true);
      expect(caps.supportsCode, true);
      expect(caps.supportsVision, false);
      expect(caps.family, 'llama');
    });

    test('should return capabilities for model with tag', () {
      final caps = ModelCapabilitiesRegistry.getCapabilities('llama3.3:70b');
      expect(caps.supportsTools, true);
      expect(caps.family, 'llama');
    });

    test('should return capabilities for vision model', () {
      final caps = ModelCapabilitiesRegistry.getCapabilities('llava');
      expect(caps.supportsVision, true);
      expect(caps.family, 'llava');
    });

    test('should return capabilities for qwen models', () {
      final caps = ModelCapabilitiesRegistry.getCapabilities('qwen2.5-coder:7b');
      expect(caps.supportsTools, true);
      expect(caps.supportsCode, true);
      expect(caps.family, 'qwen');
    });

    test('should return unknown for unrecognized model', () {
      final caps = ModelCapabilitiesRegistry.getCapabilities('totally-unknown-model');
      expect(caps, ModelCapabilities.unknown);
    });

    test('should check vision support correctly', () {
      expect(ModelCapabilitiesRegistry.supportsVision('llava'), true);
      expect(ModelCapabilitiesRegistry.supportsVision('gemma3'), true);
      expect(ModelCapabilitiesRegistry.supportsVision('llama3.3'), false);
    });

    test('should check tools support correctly', () {
      expect(ModelCapabilitiesRegistry.supportsTools('llama3.3'), true);
      expect(ModelCapabilitiesRegistry.supportsTools('qwen3'), true);
      expect(ModelCapabilitiesRegistry.supportsTools('llama2'), false);
    });

    test('should check code support correctly', () {
      expect(ModelCapabilitiesRegistry.supportsCode('codestral'), true);
      expect(ModelCapabilitiesRegistry.supportsCode('deepseek-coder'), true);
      expect(ModelCapabilitiesRegistry.supportsCode('falcon'), false);
    });

    test('should get context length correctly', () {
      expect(ModelCapabilitiesRegistry.getContextLength('llama3.3'), 131072);
      expect(ModelCapabilitiesRegistry.getContextLength('llama2'), 4096);
    });

    test('should list known model families', () {
      final families = ModelCapabilitiesRegistry.knownModelFamilies;
      expect(families.isNotEmpty, true);
      expect(families.contains('llama3.3'), true);
      expect(families.contains('qwen3'), true);
    });

    test('should get models with specific capability', () {
      final visionModels = ModelCapabilitiesRegistry.getModelsWithCapability(vision: true);
      expect(visionModels.contains('llava'), true);
      expect(visionModels.contains('gemma3'), true);
      expect(visionModels.contains('llama3.3'), false);

      final toolModels = ModelCapabilitiesRegistry.getModelsWithCapability(tools: true);
      expect(toolModels.contains('llama3.3'), true);
      expect(toolModels.contains('llama2'), false);
    });
  });
}
