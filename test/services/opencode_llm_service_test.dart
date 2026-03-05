import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/opencode_models.dart';
import 'package:private_chat_hub/services/opencode_api_client.dart';
import 'package:private_chat_hub/services/opencode_connection_manager.dart';
import 'package:private_chat_hub/services/opencode_llm_service.dart';
import 'package:private_chat_hub/services/opencode_model_visibility_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeOpenCodeApiClient extends OpenCodeApiClient {
  final OpenCodeProviderResponse providerResponse;

  _FakeOpenCodeApiClient(this.providerResponse);

  @override
  Future<OpenCodeProviderResponse> getProviders() async {
    return providerResponse;
  }
}

class _FakeOpenCodeConnectionManager extends OpenCodeConnectionManager {
  final OpenCodeApiClient _fakeClient;

  _FakeOpenCodeConnectionManager(this._fakeClient);

  @override
  OpenCodeApiClient get client => _fakeClient;

  @override
  Future<bool> testConnection() async => true;
}

void main() {
  late SharedPreferences prefs;
  late OpenCodeModelVisibilityService visibilityService;

  OpenCodeProviderResponse buildProviderResponse() {
    return OpenCodeProviderResponse(
      providers: [
        OpenCodeProvider(
          id: 'copilot',
          name: 'GitHub Copilot',
          models: {
            'gpt-4o': const OpenCodeModelDef(
              modelKey: 'gpt-4o',
              name: 'GPT-4o',
              toolCall: true,
            ),
          },
        ),
        OpenCodeProvider(
          id: 'anthropic',
          name: 'Anthropic',
          models: {
            'claude-3-5-sonnet': const OpenCodeModelDef(
              modelKey: 'claude-3-5-sonnet',
              name: 'Claude 3.5 Sonnet',
              reasoning: true,
            ),
          },
        ),
      ],
      connected: const ['copilot'],
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    visibilityService = OpenCodeModelVisibilityService(prefs);
  });

  test('returns only connected provider models by default', () async {
    final service = OpenCodeLLMService(
      _FakeOpenCodeConnectionManager(
        _FakeOpenCodeApiClient(buildProviderResponse()),
      ),
      visibilityService: visibilityService,
    );

    final models = await service.getAvailableModels();
    expect(models.map((m) => m.id), ['opencode:copilot/gpt-4o']);
  });

  test('respects explicit provider filter when configured', () async {
    await visibilityService.setVisibleProviderIds({'anthropic'});

    final service = OpenCodeLLMService(
      _FakeOpenCodeConnectionManager(
        _FakeOpenCodeApiClient(buildProviderResponse()),
      ),
      visibilityService: visibilityService,
    );

    final models = await service.getAvailableModels();
    expect(models.map((m) => m.id), ['opencode:anthropic/claude-3-5-sonnet']);
  });

  test('can fetch all providers when filter is disabled', () async {
    final service = OpenCodeLLMService(
      _FakeOpenCodeConnectionManager(
        _FakeOpenCodeApiClient(buildProviderResponse()),
      ),
      visibilityService: visibilityService,
    );

    final models = await service.getAvailableModelsForSelection(
      applyProviderFilter: false,
    );

    expect(models.map((m) => m.id).toSet(), {
      'opencode:copilot/gpt-4o',
      'opencode:anthropic/claude-3-5-sonnet',
    });
  });
}
