/// Represents a saved Ollama connection profile.
class Connection {
  final String id;
  final String name;
  final String host;
  final int port;
  final bool useHttps;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? lastConnectedAt;

  const Connection({
    required this.id,
    required this.name,
    required this.host,
    this.port = 11434,
    this.useHttps = false,
    this.isDefault = false,
    required this.createdAt,
    this.lastConnectedAt,
  });

  /// Creates a Connection from JSON map.
  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'] as String,
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int? ?? 11434,
      useHttps: json['useHttps'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastConnectedAt: json['lastConnectedAt'] != null
          ? DateTime.parse(json['lastConnectedAt'] as String)
          : null,
    );
  }

  /// Converts Connection to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'useHttps': useHttps,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'lastConnectedAt': lastConnectedAt?.toIso8601String(),
    };
  }

  /// Gets the full URL for this connection.
  String get url => '${useHttps ? 'https' : 'http'}://$host:$port';

  /// Creates a copy with updated fields.
  Connection copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    bool? useHttps,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? lastConnectedAt,
  }) {
    return Connection(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      useHttps: useHttps ?? this.useHttps,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Connection &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
