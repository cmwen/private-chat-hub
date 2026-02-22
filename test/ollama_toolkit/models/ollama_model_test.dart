import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/ollama_toolkit/models/ollama_model.dart';

void main() {
  group('ModelRegistry', () {
    test('gets capabilities for llama3.2', () {
      final caps = ModelRegistry.getCapabilities('llama3.2');

      expect(caps, isNotNull);
      expect(caps!.supportsToolCalling, true);
      expect(caps.supportsVision, true);
      expect(caps.contextWindow, 128000);
      expect(caps.modelFamily, 'llama');
    });

    test('gets capabilities for qwen2.5', () {
      final caps = ModelRegistry.getCapabilities('qwen2.5');

      expect(caps, isNotNull);
      expect(caps!.supportsToolCalling, true);
      expect(caps.supportsVision, false);
      expect(caps.contextWindow, 128000);
    });

    test('gets capabilities for deepseek-v3', () {
      final caps = ModelRegistry.getCapabilities('deepseek-v3');

      expect(caps, isNotNull);
      expect(caps!.supportsThinking, true);
      expect(caps.supportsToolCalling, true);
    });

    test('normalizes model names with version tags', () {
      final caps1 = ModelRegistry.getCapabilities('llama3.2:8b');
      final caps2 = ModelRegistry.getCapabilities('llama3.2');

      expect(caps1, isNotNull);
      expect(caps2, isNotNull);
      expect(caps1!.modelFamily, caps2!.modelFamily);
    });

    test('returns null for unknown model', () {
      final caps = ModelRegistry.getCapabilities('unknown-model');

      expect(caps, isNull);
    });

    test('finds models by tool calling capability', () {
      final models = ModelRegistry.findModelsByCapability(
        supportsToolCalling: true,
      );

      expect(models, isNotEmpty);
      expect(models, contains('llama3.2'));
      expect(models, contains('qwen2.5'));
      expect(models, contains('mistral'));
    });

    test('finds models by vision capability', () {
      final models = ModelRegistry.findModelsByCapability(supportsVision: true);

      expect(models, isNotEmpty);
      expect(models, contains('llama3.2'));
      expect(models, contains('pixtral'));
    });

    test('finds models by thinking capability', () {
      final models = ModelRegistry.findModelsByCapability(
        supportsThinking: true,
      );

      expect(models, contains('deepseek-v3'));
    });

    test('finds models by model family', () {
      final models = ModelRegistry.findModelsByCapability(
        modelFamily: 'mistral',
      );

      expect(models, isNotEmpty);
      expect(models, contains('mistral'));
      expect(models, contains('mixtral'));
      expect(models, contains('codestral'));
    });

    test('finds models with multiple criteria', () {
      final models = ModelRegistry.findModelsByCapability(
        supportsToolCalling: true,
        supportsVision: true,
      );

      expect(models, contains('llama3.2'));
      expect(models, contains('pixtral'));
      // Should not contain models without vision
      expect(models, isNot(contains('mistral')));
    });

    test('gets all model names', () {
      final models = ModelRegistry.getAllModelNames();

      expect(models, isNotEmpty);
      expect(models, contains('llama3.2'));
      expect(models, contains('qwen2.5'));
      expect(models, contains('deepseek-v3'));
    });

    test('gets all model families', () {
      final families = ModelRegistry.getAllModelFamilies();

      expect(families, isNotEmpty);
      expect(families, contains('llama'));
      expect(families, contains('qwen'));
      expect(families, contains('mistral'));
      expect(families, contains('deepseek'));
    });

    test('checks if model supports tool calling', () {
      expect(ModelRegistry.supportsToolCalling('llama3.2'), true);
      expect(ModelRegistry.supportsToolCalling('phi3'), false);
    });

    test('checks if model supports vision', () {
      expect(ModelRegistry.supportsVision('llama3.2'), true);
      expect(ModelRegistry.supportsVision('mistral'), false);
    });

    test('checks if model supports audio', () {
      expect(ModelRegistry.supportsAudio('llama3.2'), false);
      expect(ModelRegistry.supportsAudio('mistral'), false);
    });

    test('checks if model supports thinking', () {
      expect(ModelRegistry.supportsThinking('deepseek-v3'), true);
      expect(ModelRegistry.supportsThinking('llama3.2'), false);
    });
  });

  group('ModelCapabilities', () {
    test('creates capabilities with all features', () {
      final caps = ModelCapabilities(
        supportsToolCalling: true,
        supportsVision: true,
        supportsAudio: true,
        supportsThinking: true,
        contextWindow: 256000,
        modelFamily: 'test',
        aliases: ['test:1b', 'test:7b'],
      );

      expect(caps.supportsToolCalling, true);
      expect(caps.supportsVision, true);
      expect(caps.supportsAudio, true);
      expect(caps.supportsThinking, true);
      expect(caps.contextWindow, 256000);
      expect(caps.aliases, hasLength(2));
    });

    test('toString shows capabilities', () {
      final caps = ModelCapabilities(
        supportsToolCalling: true,
        supportsVision: false,
        supportsThinking: false,
        contextWindow: 128000,
      );

      final str = caps.toString();
      expect(str, contains('🔧 tools'));
      expect(str, contains('128k'));
    });
  });
}
