// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OllamaProviderConfigImpl _$$OllamaProviderConfigImplFromJson(
  Map<String, dynamic> json,
) => _$OllamaProviderConfigImpl(
  host: json['host'] as String,
  port: (json['port'] as num?)?.toInt() ?? 11434,
  modelName: json['modelName'] as String,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$OllamaProviderConfigImplToJson(
  _$OllamaProviderConfigImpl instance,
) => <String, dynamic>{
  'host': instance.host,
  'port': instance.port,
  'modelName': instance.modelName,
  'runtimeType': instance.$type,
};

_$LiteRTProviderConfigImpl _$$LiteRTProviderConfigImplFromJson(
  Map<String, dynamic> json,
) => _$LiteRTProviderConfigImpl(
  modelPath: json['modelPath'] as String,
  maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 512,
  temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
  topK: (json['topK'] as num?)?.toInt() ?? 40,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$LiteRTProviderConfigImplToJson(
  _$LiteRTProviderConfigImpl instance,
) => <String, dynamic>{
  'modelPath': instance.modelPath,
  'maxTokens': instance.maxTokens,
  'temperature': instance.temperature,
  'topK': instance.topK,
  'runtimeType': instance.$type,
};

_$OpenAIProviderConfigImpl _$$OpenAIProviderConfigImplFromJson(
  Map<String, dynamic> json,
) => _$OpenAIProviderConfigImpl(
  baseUrl: json['baseUrl'] as String,
  apiKey: json['apiKey'] as String,
  modelName: json['modelName'] as String,
  temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
  maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 2000,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$OpenAIProviderConfigImplToJson(
  _$OpenAIProviderConfigImpl instance,
) => <String, dynamic>{
  'baseUrl': instance.baseUrl,
  'apiKey': instance.apiKey,
  'modelName': instance.modelName,
  'temperature': instance.temperature,
  'maxTokens': instance.maxTokens,
  'runtimeType': instance.$type,
};
