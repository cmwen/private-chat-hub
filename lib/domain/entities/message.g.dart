// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MessageImpl _$$MessageImplFromJson(
  Map<String, dynamic> json,
) => _$MessageImpl(
  id: (json['id'] as num).toInt(),
  conversationId: (json['conversationId'] as num).toInt(),
  role: $enumDecode(_$MessageRoleEnumMap, json['role']),
  content: json['content'] as String,
  modelName: json['modelName'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  tokenCount: (json['tokenCount'] as num?)?.toInt(),
  images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
  files: (json['files'] as List<dynamic>?)?.map((e) => e as String).toList(),
  status:
      $enumDecodeNullable(_$MessageStatusEnumMap, json['status']) ??
      MessageStatus.sent,
  errorMessage: json['errorMessage'] as String?,
);

Map<String, dynamic> _$$MessageImplToJson(_$MessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'role': _$MessageRoleEnumMap[instance.role]!,
      'content': instance.content,
      'modelName': instance.modelName,
      'createdAt': instance.createdAt.toIso8601String(),
      'tokenCount': instance.tokenCount,
      'images': instance.images,
      'files': instance.files,
      'status': _$MessageStatusEnumMap[instance.status]!,
      'errorMessage': instance.errorMessage,
    };

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.assistant: 'assistant',
  MessageRole.system: 'system',
};

const _$MessageStatusEnumMap = {
  MessageStatus.pending: 'pending',
  MessageStatus.sent: 'sent',
  MessageStatus.error: 'error',
};
