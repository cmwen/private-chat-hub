import 'package:private_chat_hub/models/ai_provider.dart';
import 'package:private_chat_hub/models/provider_connection.dart';
import 'package:private_chat_hub/services/provider_selection_service.dart';
import 'package:private_chat_hub/services/connection_service.dart';
import 'package:private_chat_hub/services/lite_llm_config_service.dart';

class AiConnectionService {
  final ProviderSelectionService _providerConfig;
  final ConnectionService _ollamaService;
  final LiteLlmConfigService _liteLlmService;

  AiConnectionService({
    required ProviderSelectionService providerConfig,
    required ConnectionService ollamaService,
    required LiteLlmConfigService liteLlmService,
  }) : _providerConfig = providerConfig,
       _ollamaService = ollamaService,
       _liteLlmService = liteLlmService;

  AiProviderType getSelectedProvider() => _providerConfig.getSelectedProvider();

  Future<void> setSelectedProvider(AiProviderType providerType) async {
    await _providerConfig.setSelectedProvider(providerType);
  }

  ProviderConnection getActiveConnection() {
    final providerType = getSelectedProvider();
    return getConnectionForProvider(providerType);
  }

  ProviderConnection getConnectionForProvider(AiProviderType providerType) {
    switch (providerType) {
      case AiProviderType.ollama:
        return ProviderConnection(
          providerType: providerType,
          ollamaConnection: _ollamaService.getDefaultConnection(),
        );
      case AiProviderType.liteLlm:
        return ProviderConnection(
          providerType: providerType,
          liteLlmConnection: _liteLlmService.getDefaultConnection(),
        );
    }
  }
}
