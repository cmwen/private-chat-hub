enum AiProviderType { ollama, liteLlm }

extension AiProviderTypeExtensions on AiProviderType {
  String get label {
    switch (this) {
      case AiProviderType.ollama:
        return 'Ollama';
      case AiProviderType.liteLlm:
        return 'LiteLLM';
    }
  }
}

AiProviderType parseAiProviderType(String? value) {
  switch (value) {
    case 'liteLlm':
      return AiProviderType.liteLlm;
    case 'ollama':
    default:
      return AiProviderType.ollama;
  }
}
