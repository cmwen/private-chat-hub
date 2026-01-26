import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_provider.freezed.dart';
part 'model_provider.g.dart';

enum ModelProviderType { ollama, litert, openai }

@freezed
class ModelProviderConfig with _$ModelProviderConfig {
  const factory ModelProviderConfig.ollama({
    required String host,
    @Default(11434) int port,
    required String modelName,
  }) = OllamaProviderConfig;

  const factory ModelProviderConfig.litert({
    required String modelPath,
    @Default(512) int maxTokens,
    @Default(0.7) double temperature,
    @Default(40) int topK,
  }) = LiteRTProviderConfig;

  const factory ModelProviderConfig.openai({
    required String baseUrl,
    required String apiKey,
    required String modelName,
    @Default(0.7) double temperature,
    @Default(2000) int maxTokens,
  }) = OpenAIProviderConfig;

  const ModelProviderConfig._();

  factory ModelProviderConfig.fromJson(Map<String, dynamic> json) =>
      _$ModelProviderConfigFromJson(json);

  ModelProviderType get type {
    return map(
      ollama: (_) => ModelProviderType.ollama,
      litert: (_) => ModelProviderType.litert,
      openai: (_) => ModelProviderType.openai,
    );
  }

  String get displayName {
    return map(
      ollama: (config) => 'Ollama - ${config.modelName}',
      litert: (config) => 'LiteRT - ${config.modelPath.split('/').last}',
      openai: (config) => 'OpenAI - ${config.modelName}',
    );
  }
}
