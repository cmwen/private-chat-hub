import 'package:private_chat_hub/ollama_toolkit/models/ollama_model.dart';

class ProviderModelInfo {
  final String name;
  final String? sizeFormatted;
  final String? parameterCount;
  final ModelCapabilities? capabilities;

  const ProviderModelInfo({
    required this.name,
    this.sizeFormatted,
    this.parameterCount,
    this.capabilities,
  });
}
