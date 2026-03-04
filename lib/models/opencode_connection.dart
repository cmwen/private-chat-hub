/// Represents a saved OpenCode server connection profile.
class OpenCodeConnection {
  final String id;
  final String name;
  final String host;
  final int port;
  final bool useHttps;
  final String? username;
  final String? password;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? lastConnectedAt;

  const OpenCodeConnection({
    required this.id,
    required this.name,
    required this.host,
    this.port = 4096,
    this.useHttps = false,
    this.username,
    this.password,
    this.isDefault = false,
    required this.createdAt,
    this.lastConnectedAt,
  });

  factory OpenCodeConnection.fromJson(Map<String, dynamic> json) {
    return OpenCodeConnection(
      id: json['id'] as String,
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int? ?? 4096,
      useHttps: json['useHttps'] as bool? ?? false,
      username: json['username'] as String?,
      password: json['password'] as String?,
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
      'username': username,
      'password': password,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'lastConnectedAt': lastConnectedAt?.toIso8601String(),
    };
  }

  /// Gets the full URL for this connection.
  String get url => '${useHttps ? 'https' : 'http'}://$host:$port';

  /// Whether HTTP basic auth is configured.
  bool get hasAuth => password != null && password!.isNotEmpty;

  OpenCodeConnection copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    bool? useHttps,
    String? username,
    String? password,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? lastConnectedAt,
  }) {
    return OpenCodeConnection(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      useHttps: useHttps ?? this.useHttps,
      username: username ?? this.username,
      password: password ?? this.password,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpenCodeConnection &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
