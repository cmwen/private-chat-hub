// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConnectionProfileImpl _$$ConnectionProfileImplFromJson(
  Map<String, dynamic> json,
) => _$ConnectionProfileImpl(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  host: json['host'] as String,
  port: (json['port'] as num?)?.toInt() ?? 11434,
  isDefault: json['isDefault'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$ConnectionProfileImplToJson(
  _$ConnectionProfileImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'host': instance.host,
  'port': instance.port,
  'isDefault': instance.isDefault,
  'createdAt': instance.createdAt.toIso8601String(),
};

_$ConnectionHealthImpl _$$ConnectionHealthImplFromJson(
  Map<String, dynamic> json,
) => _$ConnectionHealthImpl(
  status: $enumDecode(_$ConnectionStatusEnumMap, json['status']),
  lastCheck: DateTime.parse(json['lastCheck'] as String),
  successRate: (json['successRate'] as num?)?.toDouble() ?? 1.0,
  avgLatency: json['avgLatency'] == null
      ? null
      : Duration(microseconds: (json['avgLatency'] as num).toInt()),
  errorMessage: json['errorMessage'] as String?,
  nextAvailableAt: json['nextAvailableAt'] == null
      ? null
      : DateTime.parse(json['nextAvailableAt'] as String),
);

Map<String, dynamic> _$$ConnectionHealthImplToJson(
  _$ConnectionHealthImpl instance,
) => <String, dynamic>{
  'status': _$ConnectionStatusEnumMap[instance.status]!,
  'lastCheck': instance.lastCheck.toIso8601String(),
  'successRate': instance.successRate,
  'avgLatency': instance.avgLatency?.inMicroseconds,
  'errorMessage': instance.errorMessage,
  'nextAvailableAt': instance.nextAvailableAt?.toIso8601String(),
};

const _$ConnectionStatusEnumMap = {
  ConnectionStatus.connected: 'connected',
  ConnectionStatus.connecting: 'connecting',
  ConnectionStatus.disconnected: 'disconnected',
  ConnectionStatus.error: 'error',
};
