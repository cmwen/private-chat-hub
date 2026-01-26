// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'litert_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LiteRTModelImpl _$$LiteRTModelImplFromJson(Map<String, dynamic> json) =>
    _$LiteRTModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      localPath: json['localPath'] as String,
      status: $enumDecode(_$LiteRTModelStatusEnumMap, json['status']),
      sizeInBytes: (json['sizeInBytes'] as num?)?.toInt(),
      downloadProgress: (json['downloadProgress'] as num?)?.toInt(),
      errorMessage: json['errorMessage'] as String?,
      lastUsed: json['lastUsed'] == null
          ? null
          : DateTime.parse(json['lastUsed'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$LiteRTModelImplToJson(_$LiteRTModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'localPath': instance.localPath,
      'status': _$LiteRTModelStatusEnumMap[instance.status]!,
      'sizeInBytes': instance.sizeInBytes,
      'downloadProgress': instance.downloadProgress,
      'errorMessage': instance.errorMessage,
      'lastUsed': instance.lastUsed?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$LiteRTModelStatusEnumMap = {
  LiteRTModelStatus.available: 'available',
  LiteRTModelStatus.downloading: 'downloading',
  LiteRTModelStatus.ready: 'ready',
  LiteRTModelStatus.error: 'error',
};
