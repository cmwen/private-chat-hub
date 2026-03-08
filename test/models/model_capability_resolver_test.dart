import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/model_capability_resolver.dart';

void main() {
  group('ModelCapabilityResolver', () {
    test('resolves local on-device model capabilities', () {
      final caps = ModelCapabilityResolver.getCapabilities(
        'local:gemma-3n-e2b',
      );

      expect(caps, isNotNull);
      expect(caps!.supportsVision, true);
      expect(caps.supportsAudio, true);
      expect(caps.supportsToolCalling, true);
      expect(caps.modelFamily, 'gemma');
    });

    test('resolves remote Ollama model capabilities', () {
      final caps = ModelCapabilityResolver.getCapabilities('llama3.2:3b');

      expect(caps, isNotNull);
      expect(caps!.supportsVision, true);
      expect(caps.supportsToolCalling, true);
      expect(caps.supportsAudio, false);
    });

    test('returns unknown capabilities for unrecognized model', () {
      final caps = ModelCapabilityResolver.getCapabilitiesOrUnknown(
        'local:unknown-model',
      );

      expect(caps.supportsVision, false);
      expect(caps.supportsAudio, false);
      expect(caps.supportsToolCalling, false);
      expect(caps.description, 'Unknown model');
    });

    group('OpenCode model capabilities', () {
      test('Anthropic claude model has tools and vision', () {
        final caps = ModelCapabilityResolver.getCapabilities(
          'opencode:anthropic/claude-3-5-sonnet',
        );
        expect(caps, isNotNull);
        expect(caps!.supportsToolCalling, true);
        expect(caps.supportsVision, true);
        expect(caps.supportsThinking, false);
      });

      test('Anthropic claude-3-7 model has thinking', () {
        final caps = ModelCapabilityResolver.getCapabilities(
          'opencode:anthropic/claude-3-7-sonnet',
        );
        expect(caps, isNotNull);
        expect(caps!.supportsThinking, true);
      });

      test('OpenAI gpt-4o model has tools and vision', () {
        final caps = ModelCapabilityResolver.getCapabilities(
          'opencode:openai/gpt-4o',
        );
        expect(caps, isNotNull);
        expect(caps!.supportsToolCalling, true);
        expect(caps.supportsVision, true);
      });

      test('OpenAI o1 model has thinking', () {
        final caps = ModelCapabilityResolver.getCapabilities(
          'opencode:openai/o1-mini',
        );
        expect(caps, isNotNull);
        expect(caps!.supportsThinking, true);
      });

      test('Google gemini model has tools and vision', () {
        final caps = ModelCapabilityResolver.getCapabilities(
          'opencode:google/gemini-2.0-flash',
        );
        expect(caps, isNotNull);
        expect(caps!.supportsToolCalling, true);
        expect(caps.supportsVision, true);
      });

      test('GitHub Copilot gpt-4o has vision', () {
        final caps = ModelCapabilityResolver.getCapabilities(
          'opencode:copilot/gpt-4o',
        );
        expect(caps, isNotNull);
        expect(caps!.supportsVision, true);
      });

      test('Unknown provider has tools but no vision by default', () {
        final caps = ModelCapabilityResolver.getCapabilities(
          'opencode:some-provider/some-model',
        );
        expect(caps, isNotNull);
        expect(caps!.supportsToolCalling, true);
        expect(caps.supportsVision, false);
      });

      test('OpenCode model description includes provider name', () {
        final caps = ModelCapabilityResolver.getCapabilities(
          'opencode:deepseek/deepseek-v3',
        );
        expect(caps, isNotNull);
        expect(caps!.description, contains('deepseek'));
      });

      test('supportsToolCalling helper returns true for OpenCode models', () {
        expect(
          ModelCapabilityResolver.supportsToolCalling(
            'opencode:anthropic/claude-3-5-sonnet',
          ),
          true,
        );
      });

      test('supportsVision helper returns true for vision-capable models', () {
        expect(
          ModelCapabilityResolver.supportsVision(
            'opencode:google/gemini-1.5-pro',
          ),
          true,
        );
      });
    });
  });
}
