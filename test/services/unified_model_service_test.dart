import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/services/llm_service.dart';
import 'package:private_chat_hub/services/unified_model_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UnifiedModelService model ID helpers', () {
    test('detects model source prefixes', () {
      expect(UnifiedModelService.isLocalModel('local:gemma-3n'), isTrue);
      expect(
        UnifiedModelService.isOpenCodeModel('opencode:openai/gpt-4o'),
        isTrue,
      );
      expect(UnifiedModelService.isLocalModel('llama3.2:latest'), isFalse);
      expect(UnifiedModelService.isOpenCodeModel('llama3.2:latest'), isFalse);
    });

    test('normalizes display names by source', () {
      expect(UnifiedModelService.getDisplayName('local:gemma-3n'), 'gemma-3n');
      expect(
        UnifiedModelService.getDisplayName('opencode:openai/gpt-4o'),
        'openai/gpt-4o',
      );
      expect(
        UnifiedModelService.getDisplayName('llama3.2:latest'),
        'llama3.2:latest',
      );
    });
  });

  group('UnifiedModelService remote model cache', () {
    test('stores only remote models', () async {
      final allModels = [
        const ModelInfo(
          id: 'local:gemma-3n',
          name: 'Gemma 3N',
          description: 'On-device model',
          sizeBytes: 100,
          isDownloaded: true,
          capabilities: ['text'],
          isLocal: true,
        ),
        const ModelInfo(
          id: 'llama3.2:latest',
          name: 'Llama 3.2',
          description: 'Ollama model',
          sizeBytes: 200,
          isDownloaded: true,
          capabilities: ['text'],
          isLocal: false,
        ),
        const ModelInfo(
          id: 'opencode:openai/gpt-4o',
          name: 'GPT-4o',
          description: 'OpenCode model',
          sizeBytes: 0,
          isDownloaded: true,
          capabilities: ['text', 'tools'],
          isLocal: false,
        ),
      ];

      await UnifiedModelService.cacheRemoteModels(allModels);
      final cached = await UnifiedModelService.getCachedRemoteModels();

      expect(cached.map((m) => m.id), [
        'llama3.2:latest',
        'opencode:openai/gpt-4o',
      ]);
      expect(cached.every((m) => m.isLocal == false), isTrue);
    });

    test('returns empty list for malformed cache payload', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('cached_remote_models', ['{not-json']);

      final cached = await UnifiedModelService.getCachedRemoteModels();
      expect(cached, isEmpty);
    });
  });
}
