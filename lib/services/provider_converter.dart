import 'package:private_chat_hub/models/provider_models.dart';
import 'package:private_chat_hub/ollama_toolkit/models/ollama_response.dart';

ProviderModelInfo fromOllamaModelInfo(OllamaModelInfo model) {
  return ProviderModelInfo(
    name: model.name,
    sizeFormatted: model.sizeFormatted,
    parameterCount: model.parameterCount,
    capabilities: model.capabilities,
  );
}
