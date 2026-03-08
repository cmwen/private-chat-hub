import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/lm_studio_connection.dart';
import 'package:private_chat_hub/models/lm_studio_models.dart';
import 'package:private_chat_hub/services/lm_studio_api_client.dart';
import 'package:private_chat_hub/services/lm_studio_connection_manager.dart';
import 'package:private_chat_hub/services/lm_studio_llm_service.dart';

class _FakeLmStudioApiClient extends LmStudioApiClient {
  LmStudioModelsResponse modelsResponse = const LmStudioModelsResponse(
    models: [],
  );
  LmStudioChatResult chatResponse = const LmStudioChatResult(output: []);
  List<LmStudioChatStreamEvent> streamEvents = const [];
  bool failStream = false;

  @override
  void setConnection(LmStudioConnection connection) {}

  @override
  Future<bool> checkHealth() async => true;

  @override
  Future<LmStudioModelsResponse> listModels() async => modelsResponse;

  @override
  Stream<LmStudioChatStreamEvent> chatStream({
    required String modelId,
    required String prompt,
    List<dynamic>? attachments,
    String? systemPrompt,
    double temperature = 0.7,
    int? maxTokens,
    String? previousResponseId,
  }) async* {
    if (failStream) {
      throw Exception('stream failure');
    }
    for (final event in streamEvents) {
      yield event;
    }
  }

  @override
  Future<LmStudioChatResult> chat({
    required String modelId,
    required String prompt,
    List<dynamic>? attachments,
    String? systemPrompt,
    double temperature = 0.7,
    int? maxTokens,
    String? previousResponseId,
  }) async {
    return chatResponse;
  }
}

void main() {
  group('LmStudioLLMService', () {
    late _FakeLmStudioApiClient apiClient;
    late LmStudioConnectionManager connectionManager;
    late LmStudioLLMService service;

    setUp(() async {
      apiClient = _FakeLmStudioApiClient();
      connectionManager = LmStudioConnectionManager(client: apiClient);
      service = LmStudioLLMService(connectionManager);

      await connectionManager.setConnection(
        LmStudioConnection(
          id: 'default',
          name: 'LM Studio',
          host: '127.0.0.1',
          createdAt: DateTime(2026),
        ),
      );
    });

    test('maps listed models to prefixed ModelInfo IDs', () async {
      apiClient.modelsResponse = LmStudioModelsResponse(
        models: [
          LmStudioModel(
            type: 'llm',
            publisher: 'lmstudio-community',
            key: 'gemma-3-270m-it-qat',
            displayName: 'Gemma 3 270m Instruct Qat',
            sizeBytes: 241410208,
            maxContextLength: 32768,
            capabilities: const LmStudioCapabilities(
              vision: false,
              trainedForToolUse: true,
            ),
          ),
        ],
      );

      final models = await service.getAvailableModels();

      expect(models, hasLength(1));
      expect(models.first.id, 'lmstudio:gemma-3-270m-it-qat');
      expect(models.first.name, 'Gemma 3 270m Instruct Qat');
      expect(models.first.capabilities, contains('tools'));
    });

    test('streams message deltas from SSE events', () async {
      apiClient.streamEvents = const [
        LmStudioChatStreamEvent(
          type: 'message.delta',
          data: {'content': 'Hello '},
        ),
        LmStudioChatStreamEvent(
          type: 'message.delta',
          data: {'content': 'world'},
        ),
      ];

      final tokens = await service
          .generateResponse(prompt: 'Hi', modelId: 'lmstudio:test-model')
          .toList();

      expect(tokens.join(), 'Hello world');
    });

    test('falls back to non-streaming response when stream fails', () async {
      apiClient.failStream = true;
      apiClient.chatResponse = const LmStudioChatResult(
        output: [
          {'type': 'message', 'content': 'Recovered response'},
        ],
      );

      final tokens = await service
          .generateResponse(prompt: 'Hi', modelId: 'lmstudio:test-model')
          .toList();

      expect(tokens.join(), 'Recovered response');
    });
  });
}
