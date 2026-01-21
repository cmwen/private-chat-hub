import 'package:private_chat_hub/models/ai_provider.dart';
import 'package:private_chat_hub/models/connection.dart';
import 'package:private_chat_hub/models/lite_llm_connection.dart';

class ProviderConnection {
  final AiProviderType providerType;
  final Connection? ollamaConnection;
  final LiteLlmConnection? liteLlmConnection;

  const ProviderConnection({
    required this.providerType,
    this.ollamaConnection,
    this.liteLlmConnection,
  });

  String get displayName {
    switch (providerType) {
      case AiProviderType.ollama:
        return ollamaConnection?.name ?? 'Ollama';
      case AiProviderType.liteLlm:
        return liteLlmConnection?.name ?? 'LiteLLM';
    }
  }

  bool get isConfigured {
    switch (providerType) {
      case AiProviderType.ollama:
        return ollamaConnection != null;
      case AiProviderType.liteLlm:
        return liteLlmConnection != null;
    }
  }
}
