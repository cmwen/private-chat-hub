import 'package:private_chat_hub/models/ai_provider.dart';
import 'package:private_chat_hub/models/provider_connection.dart';
import 'package:private_chat_hub/services/lite_llm_client.dart';
import 'package:private_chat_hub/services/lite_llm_secure_storage.dart';
import 'package:private_chat_hub/services/ollama_connection_manager.dart';
import 'package:private_chat_hub/services/provider_chat_client.dart';

class ProviderClientFactory {
  final OllamaConnectionManager _ollamaManager;
  final LiteLlmSecureStorage _secureStorage;

  ProviderClientFactory(this._ollamaManager, this._secureStorage);

  Future<ProviderChatClient?> createClient(
    ProviderConnection connection,
  ) async {
    switch (connection.providerType) {
      case AiProviderType.ollama:
        if (connection.ollamaConnection == null) return null;
        _ollamaManager.setConnection(connection.ollamaConnection!);
        final client = _ollamaManager.client;
        if (client == null) return null;
        return OllamaProviderChatClient(client);
      case AiProviderType.liteLlm:
        final liteConnection = connection.liteLlmConnection;
        if (liteConnection == null) return null;
        final apiKey = await _secureStorage.getApiKey();
        return LiteLlmProviderChatClient(
          LiteLlmClient(
            baseUrl: liteConnection.baseUrl,
            timeout: _ollamaManager.timeout,
            apiKey: apiKey,
          ),
        );
    }
  }
}
