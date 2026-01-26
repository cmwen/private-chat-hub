import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection.freezed.dart';
part 'connection.g.dart';

enum ConnectionStatus { connected, connecting, disconnected, error }

@freezed
class ConnectionProfile with _$ConnectionProfile {
  const factory ConnectionProfile({
    required int id,
    required String name,
    required String host,
    @Default(11434) int port,
    @Default(false) bool isDefault,
    required DateTime createdAt,
  }) = _ConnectionProfile;

  const ConnectionProfile._();

  factory ConnectionProfile.fromJson(Map<String, dynamic> json) =>
      _$ConnectionProfileFromJson(json);

  factory ConnectionProfile.create({
    required int id,
    String? name,
    required String host,
    int port = 11434,
    bool isDefault = false,
  }) => ConnectionProfile(
    id: id,
    name: name ?? '$host:$port',
    host: host,
    port: port,
    isDefault: isDefault,
    createdAt: DateTime.now(),
  );

  String get baseUrl => 'http://$host:$port';
}

@freezed
class ConnectionHealth with _$ConnectionHealth {
  const factory ConnectionHealth({
    required ConnectionStatus status,
    required DateTime lastCheck,
    @Default(1.0) double successRate,
    Duration? avgLatency,
    String? errorMessage,
    DateTime? nextAvailableAt,
  }) = _ConnectionHealth;

  const ConnectionHealth._();

  factory ConnectionHealth.fromJson(Map<String, dynamic> json) =>
      _$ConnectionHealthFromJson(json);

  factory ConnectionHealth.connected() => ConnectionHealth(
    status: ConnectionStatus.connected,
    lastCheck: DateTime.now(),
  );

  factory ConnectionHealth.disconnected(String? errorMessage) =>
      ConnectionHealth(
        status: ConnectionStatus.disconnected,
        lastCheck: DateTime.now(),
        successRate: 0.0,
        errorMessage: errorMessage,
      );

  factory ConnectionHealth.error(String errorMessage) => ConnectionHealth(
    status: ConnectionStatus.error,
    lastCheck: DateTime.now(),
    errorMessage: errorMessage,
  );

  bool get isHealthy => status == ConnectionStatus.connected;
}
