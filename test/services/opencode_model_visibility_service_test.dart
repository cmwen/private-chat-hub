import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/services/opencode_model_visibility_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late OpenCodeModelVisibilityService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = OpenCodeModelVisibilityService(prefs);
  });

  group('OpenCodeModelVisibilityService model visibility', () {
    test('shows non-OpenCode models and hides OpenCode models before initialization', () {
      expect(service.isModelVisible('llama3.2:latest'), isTrue);
      expect(service.isModelVisible('local:gemma3-1b'), isTrue);
      expect(service.isModelVisible('opencode:copilot/gpt-4o'), isFalse);
    });

    test('toggles model visibility after initialization', () async {
      const modelId = 'opencode:copilot/gpt-4o';

      await service.toggleModel(modelId);
      expect(service.isModelVisible(modelId), isTrue);

      await service.toggleModel(modelId);
      expect(service.isModelVisible(modelId), isFalse);
    });

    test('show all and hide all update visibility set', () async {
      final all = ['llama3.2:latest', 'local:gemma3-1b'];

      await service.showAll(all);
      expect(service.getVisibleModelIds(), all.toSet());

      await service.hideAll();
      expect(service.getVisibleModelIds(), isEmpty);
    });
  });

  group('OpenCodeModelVisibilityService provider visibility', () {
    test('defaults to connected providers when no explicit provider filter', () {
      final connected = {'copilot'};

      expect(
        service.isProviderVisible('copilot', connectedProviders: connected),
        isTrue,
      );
      expect(
        service.isProviderVisible('anthropic', connectedProviders: connected),
        isFalse,
      );
    });

    test('uses explicit provider filter when configured', () async {
      await service.setVisibleProviderIds({'anthropic'});

      expect(
        service.isProviderVisible('anthropic', connectedProviders: {'copilot'}),
        isTrue,
      );
      expect(
        service.isProviderVisible('copilot', connectedProviders: {'copilot'}),
        isFalse,
      );
    });
  });
}
