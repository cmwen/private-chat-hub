import 'package:private_chat_hub/models/ai_provider.dart';

class LiteLlmConnection {
  final String id;
  final String name;
  final String baseUrl;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? lastConnectedAt;

  const LiteLlmConnection({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.isDefault = false,
    required this.createdAt,
    this.lastConnectedAt,
  });

  AiProviderType get providerType => AiProviderType.liteLlm;

  factory LiteLlmConnection.fromJson(Map<String, dynamic> json) {
    return LiteLlmConnection(
      id: json['id'] as String,
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
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
      'baseUrl': baseUrl,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'lastConnectedAt': lastConnectedAt?.toIso8601String(),
    };
  }

  LiteLlmConnection copyWith({
    String? id,
    String? name,
    String? baseUrl,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? lastConnectedAt,
  }) {
    return LiteLlmConnection(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }
}
