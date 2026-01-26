// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConversationImpl _$$ConversationImplFromJson(Map<String, dynamic> json) =>
    _$ConversationImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      modelName: json['modelName'] as String?,
      systemPrompt: json['systemPrompt'] as String?,
      isArchived: json['isArchived'] as bool? ?? false,
      messageCount: (json['messageCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ConversationImplToJson(_$ConversationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'modelName': instance.modelName,
      'systemPrompt': instance.systemPrompt,
      'isArchived': instance.isArchived,
      'messageCount': instance.messageCount,
    };
