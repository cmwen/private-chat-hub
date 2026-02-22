import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/model_capability_resolver.dart';

void main() {
  group('ModelCapabilityResolver', () {
    test('resolves local on-device model capabilities', () {
      final caps = ModelCapabilityResolver.getCapabilities('local:gemma-3n-e2b');

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
  });
}
