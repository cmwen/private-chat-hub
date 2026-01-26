// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ollama_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OllamaModelImpl _$$OllamaModelImplFromJson(Map<String, dynamic> json) =>
    _$OllamaModelImpl(
      name: json['name'] as String,
      size: (json['size'] as num).toInt(),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      digest: json['digest'] as String?,
      details: json['details'] == null
          ? null
          : ModelDetails.fromJson(json['details'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$OllamaModelImplToJson(_$OllamaModelImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'size': instance.size,
      'modifiedAt': instance.modifiedAt.toIso8601String(),
      'digest': instance.digest,
      'details': instance.details,
    };

_$ModelDetailsImpl _$$ModelDetailsImplFromJson(Map<String, dynamic> json) =>
    _$ModelDetailsImpl(
      format: json['format'] as String?,
      family: json['family'] as String?,
      parameterSize: json['parameterSize'] as String?,
      quantizationLevel: json['quantizationLevel'] as String?,
      capabilities: (json['capabilities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$ModelDetailsImplToJson(_$ModelDetailsImpl instance) =>
    <String, dynamic>{
      'format': instance.format,
      'family': instance.family,
      'parameterSize': instance.parameterSize,
      'quantizationLevel': instance.quantizationLevel,
      'capabilities': instance.capabilities,
    };

_$PullProgressImpl _$$PullProgressImplFromJson(Map<String, dynamic> json) =>
    _$PullProgressImpl(
      status: json['status'] as String,
      digest: json['digest'] as String?,
      total: (json['total'] as num?)?.toInt(),
      completed: (json['completed'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$PullProgressImplToJson(_$PullProgressImpl instance) =>
    <String, dynamic>{
      'status': instance.status,
      'digest': instance.digest,
      'total': instance.total,
      'completed': instance.completed,
    };
