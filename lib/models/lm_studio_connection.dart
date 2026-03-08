/// Represents a saved LM Studio server connection profile.
class LmStudioConnection {
  final String id;
  final String name;
  final String host;
  final int port;
  final bool useHttps;
  final String? apiToken;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? lastConnectedAt;

  const LmStudioConnection({
    required this.id,
    required this.name,
    required this.host,
    this.port = 1234,
    this.useHttps = false,
    this.apiToken,
    this.isDefault = false,
    required this.createdAt,
    this.lastConnectedAt,
  });

  factory LmStudioConnection.fromJson(Map<String, dynamic> json) {
    return LmStudioConnection(
      id: json['id'] as String,
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int? ?? 1234,
      useHttps: json['useHttps'] as bool? ?? false,
      apiToken: json['apiToken'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastConnectedAt: json['lastConnectedAt'] != null
          ? DateTime.parse(json['lastConnectedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'useHttps': useHttps,
      'apiToken': apiToken,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'lastConnectedAt': lastConnectedAt?.toIso8601String(),
    };
  }

  String get url => '${useHttps ? 'https' : 'http'}://$host:$port';

  bool get hasApiToken => apiToken != null && apiToken!.isNotEmpty;

  LmStudioConnection copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    bool? useHttps,
    String? apiToken,
    bool clearApiToken = false,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? lastConnectedAt,
  }) {
    return LmStudioConnection(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      useHttps: useHttps ?? this.useHttps,
      apiToken: clearApiToken ? null : (apiToken ?? this.apiToken),
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LmStudioConnection &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
